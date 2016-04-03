(function(window) {
  Convos.Dialog = function(attrs) {
    this.frozen   = "";
    this.id       = "";
    this.messages = [];
    this.name     = "";
    this.topic    = "";
    this._api     = Convos.api;

    EventEmitter(this);
    this.on("message", this.addMessage);
    this.once("show", this._load);

    if (attrs) this.update(attrs);
    this.active(localStorage.getItem("activeDialog") == this.href());
  };

  var proto = Convos.Dialog.prototype;

  proto.active = function(bool) {
    if (typeof bool != "boolean") return this._active;
    if (bool) {
      localStorage.setItem("activeDialog", this.href());
      this.emit("show");
    }
    this._active = bool;
    return this;
  };

  proto.addMessage = function(msg) {
    if (!msg.from)
      msg.from = "convosbot";
    if (!msg.ts)
      msg.ts = new Date();
    if (typeof msg.ts == "string")
      msg.ts = new Date(msg.ts);
    if (msg.message && this._connection) this.connection.highlightMessage(msg);
    this.messages.push(msg);
  };

  proto.groupedMessage = function(msg) {
    var prev = this.prevMessage || {
      ts: new Date()
    };
    this.prevMessage = msg;
    if (!msg.message) return false;
    return msg.from == prev.from && msg.ts.epoch() - 300 < prev.ts.epoch();
  };

  // Create a href for <a> tag
  proto.href = function() {
    var path = Array.prototype.slice.call(arguments);
    if (!this.connection) return "#chat/convos-local/convos";
    return ["#chat", this.connection.id, this.name].concat(path).join("/");
  };

  proto.icon = function() {
    return this.is_private ? "person" : "group";
  };

  proto.update = function(attrs) {
    var self = this;
    Object.keys(attrs).forEach(function(n) {
      self[n] = attrs[n];
    });
  };

  proto._convosMessages = function() {
    this.addMessage({
      message: "Welcome!"
    });
  };

  proto._initialMessages = function() {
    var topic = this.topic.replace(/"/g, "") || "";
    this.addMessage({
      message: "You have joined " + this.name + ", but no one has said anything as long as you have been here."
    });
    if (this.frozen) {
      this.addMessage({
        message: "You are not part of this channel. The reason is " + this.frozen
      });
    }
  };

  // Called when this dialog is visible in gui the first time
  proto._load = function() {
    if (!this.connection) return this._convosMessages();
    if (this.messages.length >= 60) return;
    var self = this;
    self._api.messagesByDialog(
      {
        connection_id: self.connection.id,
        dialog_id:     self.id
      }, function(err, xhr) {
        if (err) return this.emit("error", err);
        xhr.body.messages.forEach(function(msg) {
          self.addMessage(msg);
        });
        if (!self.messages.length) self._initialMessages();
      }.bind(this)
    );
  };
})(window);
