<user-register>
  <div class="row">
    <form onsubmit={submitForm} method="post" class="col s10 offset-s1 m6 offset-m3 z-depth-1">
      <div class="row">
        <div class="col s12">
          <h2>Convos</h2>
          <p><i>- Collaberation done right.</i></p>
        </div>
      </div>
      <div class="row">
        <div class="input-field col s12">
          <input placeholder="susan@example.com" name="email" id="form_email" type="email" class="validate">
          <label for="form_email">Email</label>
        </div>
      </div>
      <div class="row">
        <div class="input-field col s6">
          <input placeholder="At least six characters" name="password" id="form_password" type="password" class="validate">
          <label for="form_password">Password</label>
        </div>
        <div class="input-field col s6">
          <input placeholder="Repeat password" id="form_password_again" type="password" class="validate">
        </div>
      </div>
      <div class="row" if={formError}>
        <div class="col s12"><div class="alert">{formError}</div></div>
      </div>
      <div class="row">
        <div class="input-field col s12">
          <button class="btn waves-effect waves-light" type="submit">
            Register <i class="material-icons right">send</i>
          </button>
          <a href="#login" class="btn-flat waves-effect waves-light">Log in</a>
        </div>
      </div>
    </form>
    <div class="col s10 offset-s1 m6 offset-m3 about">
      &copy; <a href="http://nordaaker.com">Nordaaker</a> - <a href="http://convos.by">About</a>
    </div>
  </div>
  <script>

  mixin.form(this);
  mixin.http(this);

  this.convos = window.convos;

  submitForm(e) {
    localStorage.setItem('email', this.form_email.value);

    if (this.form_password.value != this.form_password_again.value) {
      $('[id^="form_password"]').addClass('invalid');
      this.formError = 'Passwords does not match';
      return;
    }

    this.formError = ''; // clear error on post
    this.httpPost(
      apiUrl('/user/register'),
      {email: this.form_email.value, password: this.form_poassword.value},
      function(err, xhr) {
        this.httpInvalidInput(xhr.responseJSON);
        if (!err) this.convos.save(xhr.responseJSON);
      }
    );
  }

  this.on('mount', function() {
    if (this.convos.email()) return Router.route('chat');
    this.form_email.value = localStorage.getItem('email');
    this.form_email.focus();
  });

  </script>
</user-register>
