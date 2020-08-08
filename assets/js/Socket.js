/**
 * Socket is a wrapper around the standard WebSocket.
 *
 * @module Socket
 * @exports geteSocket
 */

import Reactive from './Reactive';
import Time from './Time';

/**
 * getSocket() can be used to create global socket objects.
 *
 * @param {String} id A global identifier for this Socket object.
 * @returns {Object} A Socket object if no "msg" is specified.
 */
export const getSocket = (id) => {
  return getSocket.singletons[id] || (getSocket.singletons[id] = new Socket());
};

getSocket.singletons = {};

const readyStateHuman = [];
readyStateHuman[WebSocket.CONNECTING] = 'connecting';
readyStateHuman[WebSocket.OPEN] = 'open';
readyStateHuman[WebSocket.CLOSING] = 'closing';
readyStateHuman[WebSocket.CLOSED] = 'closed';

export default class Socket extends Reactive {
  constructor(params) {
    super();

    this.prop('persist', 'debug', '');
    this.prop('ro', 'readyState', () => this.ws.readyState);
    this.prop('ro', 'readyStateHuman', () => readyStateHuman[this.ws.readyState]);
    this.prop('ro', 'waiting', new Map());
    this.prop('rw', 'closed', 0);
    this.prop('rw', 'error', '');
    this.prop('rw', 'keepaliveInterval', 10000);
    this.prop('rw', 'url', '');

    this.id = 0;
    this.queue = [];
    this.keepClosed = true;
    this._resetWebSocket();
  }

  /**
   * Used to close the WebSocket connection, clear keepalive and reconnect
   * timers and make sure that the WebSocket stays closed.
   *
   * @memberof Socket
   * @param {Number} code Default to 1000.
   * @param {String} reason Default to no reason.
   * @returns {Object} Returns invocant
   */
  close(code, reason) {
    if (typeof code != 'number') [code, reason] = [1000, code];
    if (this.ws.close) this.ws.close(code, reason);
    this.keepClosed = true;
    this._keepAliveStop();
    this._reconnectStop();
    this._resetWebSocket();
    return this;
  }

  /**
   * deflateMessage() takes a data structure and converts it into a string that
   * will be passed over the WebSocket.
   *
   * @example
   * const api = new Api()
   * api.deflateMessage = (msg) => JSON.stringify(msg);
   *
   * @memberof Socket
   * @param {Object} msg A message object to serialize.
   * @returns {String}
   */
  deflateMessage(msg) {
    return JSON.stringify(msg);
  }

  /**
   * Remove a waiting message by "id". "id" can be retrieved from
   * getWaitingMessages().
   *
   * @memberof Socket
   * @param {String} id A message id.
   */
  deleteWaitingMessage(id) {
    this.waiting.delete(id);
    this.update({waiting: true});
  }

  /**
   * Get messages that have been sent to the WebSocket, but have not gotten
   * a reply. Not specifying a list of IDs will return all waiting messages.
   *
   * @param {Array} A list of message id.
   * @returns {Array} A list of messages
   */
  getWaitingMessages(ids) {
    if (arguments.length == 0) return Array.from(this.waiting.values());
    return ids.map(id => this.waiting.get(id));
  }

  /**
   * inflateMessage() takes a string and converts it into a data structure.
   *
   * @example
   * const api = new Api()
   * api.inflateMessage = (str) => JSON.parse(str);
   *
   * @memberof Socket
   * @param {String} str A message from the WebSocket
   * @returns {Object}
   */
  inflateMessage(str) {
    return JSON.parse(str);
  }

  /**
   * is() can be used to check the state.
   *
   * @example
   * api.is('connecting'); // Checks if the WebSocket is connecting
   * api.is('open');       // Checks if the WebSocket is open
   * api.is('closing');    // Checks if the WebSocket is closing
   * api.is('closed');     // Checks if the WebSocket is closed
   *
   * @memberof Socket
   * @param {Sring} state See the examples above
   * @returns {Boolean} True if the object is in the given state
   */
  is(state) {
    if (state == 'reconnecting') return this.reconnectTid ? true : false;
    const wsIs = this.ws.readyState == WebSocket[state.toUpperCase()];
    return wsIs && !this.reconnectTid;
  }

  /**
   * Used to manually open a WebSocket connection. This method will automatically
   * get called by send().
   *
   * @memberof Socket
   * @returns {Object} The invocant
   */
  open() {
    const reconnecting = this.is('reconnecting');
    if (!this.is('closed') && !reconnecting) return this;

    try {
      if (!this.url) throw 'Can\'t open WebSocket connection without URL.';
      this.ws = new WebSocket(this.url);
      this.ws.onclose = (e) => this._onClose(e);
      this.ws.onerror = (e) => this._onError(e);
      this.ws.onmessage = (e) => this._onMessage(e);
      this.ws.onopen = (e) => this._onOpen(e);
      this.keepClosed = false;
      this._keepAliveStart();
      this._reconnectStop();
      this.update({error: '', readyState: true});
    } catch(err) {
      this._resetWebSocket();
      this._onError(err.message ? err : {message: String(err)});
      if (reconnecting) this._reconnectStart(this.reconnectIn({}));
    }

    return this;
  }

  /**
   * reconnectIn() can be used to calculate when to reconnect when a WebSocket
   * connection is lost.
   *
   * @memberof Socket
   * @param {Event} e Normally a CloseEvent.
   * @returns {Number} Number of milliseconds to reconnect.
   * @returns {Boolean} False to cancel the reconnect.
   * @returns {Boolean} True to reconnect now.
   */
  reconnectIn(e) {
    if (e.code === 1008 || e.code === 1011) return false;
    return this.closed <= 1 ? 1000 : this.closed > 5 ? 10000 : 1000 * (this.closed * 2);
  }

  /**
   * Used to send a message to the server. Will also open the WebSocket, unless
   * already connected.
   *
   * @param {Object} msg A message to send to the server.
   * @returns {Promise} A promise that will get resolved when the response comes.
   */
  send(msg) {
    const id = msg.id || String(++this.id);
    this.queue.push({...msg, id});
    this.open();
    this._dequeue();
    return this.on('message_' + id);
  }

  _dequeue() {
    const queue = this.queue;
    if (queue.length) this.update({waiting: true});
    while (queue.length) {
      if (this.ws.readyState != WebSocket.OPEN) return;
      const msg = queue.shift();
      this.ws.send(this.deflateMessage(msg));
      msg.waitingForResponse = true;
      if (!msg.ts) msg.ts = new Time();
      this.waiting.set(msg.id, msg);
    }
  }

  _keepAliveStart() {
    this._keepAliveStop();
    this.keepaliveTid = setInterval(() => this.ws.readyState == WebSocket.OPEN && this.ws.send('{}'), this.keepaliveInterval);
  }

  _keepAliveStop() {
    if (this.keepaliveTid) clearTimeout(this.keepaliveTid);
    delete this.keepaliveTid;
  }

  _onClose(e) {
    if (this.debug) console.log('[Socket:close]', new Time().toISOString(), e);

    for (let [id, msg] of this.waiting) {
      if (Object.keys(msg).length <= 1) this.waiting.delete(id);
      msg.waitingForResponse = false;
    }

    this._keepAliveStop();
    this._resetWebSocket();
    this.update({closed: this.closed + 1, readyState: true, waiting: true});
    this._reconnectStart(this.reconnectIn(e));
  }

  _onError(e) {
    let error = String(e.message || e);
    if (!error || error.indexOf('[') == 0) error = 'Unknown error.';
    if (this.debug) console.log('[Socket:error]', new Time().toISOString(), error, e);
    this.update({error});
  }

  _onMessage(e) {
    const msg = this.inflateMessage(e.data);

    if (msg.id) {
      this.emit('message_' + msg.id, msg);
      this.waiting.delete(msg.id);
    }

    this.emit('message', msg);
    this.update({waiting: true});

    if (!msg.errors || msg.id) return;
    for (let id of this.waiting.keys()) this.emit('message_' + id, msg);
    this.waiting.clear();
  }

  _onOpen(e) {
    if (this.debug) console.log('[Socket:open]', new Time().toISOString(), e);
    this.update({closed: 0, error: '', readyState: true});
    this._dequeue();
  }

  _reconnectStart(delay) {
    this._reconnectStop();
    if (this.debug) console.log('[Socket:reconnect]', new Time().toISOString(), delay);
    if (delay === true) return this.open();
    if (typeof delay != 'number') return (this.keepClosed = true);
    this.reconnectTid = setTimeout(() => this.open(), delay);
  }

  _reconnectStop() {
    if (this.reconnectTid) clearTimeout(this.reconnectTid);
    delete this.reconnectTid;
  }

  _resetWebSocket() {
    this.ws = {readyState: WebSocket.CLOSED};
  }
}
