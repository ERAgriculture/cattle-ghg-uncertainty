# Round 8 — Contact / Feedback form via Web3Forms (client-side AJAX).
#
# Web3Forms (https://web3forms.com) is a free HTTP form-relay service that
# forwards POSTed form payloads to a verified email address (here: Lolita's
# CGIAR Alliance inbox). Their access keys are public-facing by design — the
# typical use case is a static-site form whose key is visible in page source.
# Abuse protection is handled server-side via captcha + rate limits, not by
# key secrecy.
#
# Round 8 design note: the free tier of Web3Forms blocks server-side POSTs
# (responding with "use our API in client side or contact support"). So we
# render a plain HTML form on the contact tab and POST from the visitor's
# browser via fetch(). The Shiny server is bypassed entirely for the relay.
# This is the pattern Web3Forms recommends for SPAs.
#
# To rotate the key: edit .WEB3FORMS_DEFAULT_KEY below.

.WEB3FORMS_DEFAULT_KEY <- "0303db40-85b2-491a-af64-a8c28972868f"
.WEB3FORMS_ENDPOINT    <- "https://api.web3forms.com/submit"

.web3forms_key <- function() {
  k <- Sys.getenv("WEB3FORMS_ACCESS_KEY", unset = "")
  if (nzchar(k)) k else .WEB3FORMS_DEFAULT_KEY
}

# Render the contact form as a self-contained HTML+JS block. The form posts
# from the browser directly to Web3Forms, parses the JSON response, and shows
# inline success/error feedback without leaving the page.
contact_form_html <- function() {
  key <- .web3forms_key()
  endpoint <- .WEB3FORMS_ENDPOINT
  sprintf('
<form id="contact-form-w3" onsubmit="return submitContactFormW3(event)" style="display:flex; flex-direction:column; gap:10px;">
  <input type="hidden" name="access_key" value="%s">
  <input type="hidden" name="from_name"  value="Cattle GHG App contact form">
  <input type="hidden" name="botcheck"   value="">
  <div>
    <label for="cf-name" style="font-weight:600; font-size:0.9rem;">Your name *</label>
    <input id="cf-name" type="text" name="name" required class="form-control"
           placeholder="First Last">
  </div>
  <div>
    <label for="cf-affiliation" style="font-weight:600; font-size:0.9rem;">Affiliation *</label>
    <input id="cf-affiliation" type="text" name="affiliation" required class="form-control"
           placeholder="Organisation / project / institution">
  </div>
  <div>
    <label for="cf-email" style="font-weight:600; font-size:0.9rem;">Email *</label>
    <input id="cf-email" type="email" name="email" required class="form-control"
           placeholder="you@example.org">
  </div>
  <div>
    <label for="cf-message" style="font-weight:600; font-size:0.9rem;">Message *</label>
    <textarea id="cf-message" name="message" rows="6" required class="form-control"
              placeholder="Tell us what you would like to share — a bug, a feature idea, a methodology question, anything."></textarea>
  </div>
  <button type="submit" class="btn btn-primary w-100" id="cf-submit">
    <i class="fa fa-paper-plane"></i> Send message
  </button>
  <div id="cf-status" style="font-size:0.85rem; color:#666; margin-top:6px;">
    <em>Submissions go directly to <a href="mailto:m.lolita@cgiar.org">m.lolita@cgiar.org</a> &mdash; usually a reply within a few working days.</em>
  </div>
</form>
<script>
async function submitContactFormW3(e) {
  e.preventDefault();
  var form = document.getElementById("contact-form-w3");
  var btn  = document.getElementById("cf-submit");
  var stat = document.getElementById("cf-status");
  // Honeypot — Web3Forms checks the "botcheck" field; if a bot fills it, drop
  if (form.botcheck && form.botcheck.value) return false;
  btn.disabled = true;
  btn.innerHTML = "<i class=\"fa fa-spinner fa-spin\"></i> Sending…";
  stat.style.color = "#666";
  stat.innerHTML  = "<em>Sending your message…</em>";

  var fd = new FormData(form);
  // Helpful subject + reply-to for Lolita\'s inbox
  fd.set("subject", "[Cattle GHG App] Feedback from " + (form.name.value || "anonymous"));
  fd.set("replyto", form.email.value || "");

  try {
    var r = await fetch("%s", {
      method: "POST",
      body: fd
    });
    var j = await r.json();
    if (j.success) {
      stat.style.background = "%s";
      stat.style.color      = "%s";
      stat.style.padding    = "10px 12px";
      stat.style.borderRadius = "6px";
      stat.innerHTML = "<i class=\"fa fa-check-circle\"></i> Message sent &mdash; Lolita will reply when she can.";
      form.reset();
    } else {
      stat.style.background = "#FECACA";
      stat.style.color      = "#7F1D1D";
      stat.style.padding    = "10px 12px";
      stat.style.borderRadius = "6px";
      stat.innerHTML = "<i class=\"fa fa-exclamation-triangle\"></i> Send failed: " +
        (j.message || "unknown error") +
        ". Please email <a href=\"mailto:m.lolita@cgiar.org\">m.lolita@cgiar.org</a> directly.";
    }
  } catch (err) {
    stat.style.background = "#FECACA";
    stat.style.color      = "#7F1D1D";
    stat.style.padding    = "10px 12px";
    stat.style.borderRadius = "6px";
    stat.innerHTML = "<i class=\"fa fa-exclamation-triangle\"></i> Network error. Please email <a href=\"mailto:m.lolita@cgiar.org\">m.lolita@cgiar.org</a> directly.";
  }
  btn.disabled = false;
  btn.innerHTML = "<i class=\"fa fa-paper-plane\"></i> Send message";
  return false;
}
</script>
', key, endpoint, "#D8F3DC", "#1B4332")
}
