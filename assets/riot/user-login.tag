<user-login>
  <div class="row not-logged-in-wrapper">
    <form onsubmit={login} class="col s10 offset-s1 m6 offset-m3">
      <div class="row">
        <div class="col s12">
          <h2>Convos</h2>
          <p><i>- Collaberation done right.</i></p>
        </div>
      </div>
      <div class="row">
        <div class="input-field col s12">
          <input placeholder="susan@example.com" name="email" id="form_email" type="email" class="tooltipped validate">
          <label for="form_email">Email</label>
        </div>
      </div>
      <div class="row">
        <div class="input-field col s12">
          <input placeholder="At least six characters" name="password" id="form_password" type="password" class="tooltipped validate">
          <label for="form_password">Password</label>
        </div>
      </div>
      <div class="row" if={errors.length}>
        <div class="col s12"><div class="alert">{errors[0].message}</div></div>
      </div>
      <div class="row">
        <div class="input-field col s12">
          <button class="btn waves-effect waves-light" type="submit" name="action">
            Log in <i class="material-icons right">send</i>
          </button>
          <a href="#register" class="btn-flat waves-effect waves-light">Register</a>
        </div>
      </div>
      <div class="row">
        <div class="col s12 about">
          &copy; <a href="http://nordaaker.com">Nordaaker</a> - <a href="http://convos.by">About</a>
        </div>
      </div>
    </form>
  </div>
  <script>

  var tag = this;
  this.errors = opts.errors;
  this.user = opts.user;
  mixin.form(this);

  login(e) {
    this.errors = []; // clear error on post
    localStorage.setItem('email', this.form_email.value);
    Convos.api.loginUser(
      {body: {email: this.form_email.value, password: this.form_password.value}},
      function(err, xhr) {
        if (err) return tag.update({errors: err});
        tag.user.update(xhr.body);
        riot.url.route('');
      }
    );
  }

  this.on('mount', function() {
    if (this.user.email()) return riot.url.route('');
    this.form_email.value = localStorage.getItem('email');
    this.form_email.focus();
  });

  </script>
</user-login>
