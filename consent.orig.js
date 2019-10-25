function SetCookie(cname, cvalue, exdays) {
  var d = new Date();
  d.setTime(d.getTime() + (exdays * 24 * 60 * 60 * 1000));
  var expires = "expires="+d.toUTCString();
  document.cookie = cname + "=" + cvalue + ";" + expires + ";path=/";
}

function DelCookie(cname) {
    SetCookie(cname, '', -1);
}

function GetCookie(cname) {
  var name = cname + "=";
  var ca = document.cookie.split(';');
  for(var i = 0; i < ca.length; i++) {
    var c = ca[i];
    while (c.charAt(0) == ' ') {
      c = c.substring(1);
    }
    if (c.indexOf(name) == 0) {
      return c.substring(name.length, c.length);
    }
  }
  return "";
}


function ShowCookieNotice() {
    var hidden_div = document.getElementById('no_div');
    var cookie_div = hidden_div.cloneNode(true);
    cookie_div.id = 'cookie_div';
    hidden_div.id = 'hidden_div';
    document.body.appendChild(cookie_div);
};

function HideCookieNotice() {
    var hidden_div = document.getElementById('hidden_div');
    hidden_div.id = 'no_div';
    var cookie_div = document.getElementById('cookie_div');
    cookie_div.parentNode.removeChild(cookie_div);
}

function HandleCookieConsent() {
    var consent = GetCookie('cookie-consent');
    if (consent == 'yes') {
        GoogleAnalytics(true);
        GoogleAdsense();
    } else if (consent == 'no') {
        GoogleAnalytics(false);
    } else {
        // Handles empty and corrupted cookie-consent cookie
        ShowCookieNotice();
    }
}

function GoogleAdsense() {
    (adsbygoogle = window.adsbygoogle || []).push({});
}

function GoogleAnalytics(enabled) {
    window['ga-disable-UA-34701218-2'] = ! enabled;
    window.dataLayer = window.dataLayer || [];
    function gtag(){dataLayer.push(arguments);}
    gtag('js', new Date());
    gtag('config', 'UA-34701218-2');
}

function AllowCookies() {
    SetCookie('cookie-consent', 'yes', 30);
    HideCookieNotice();
    GoogleAnalytics(true);
    GoogleAdsense();
}

function DisallowCookies() {
    SetCookie('cookie-consent', 'no', 10);
    HideCookieNotice();
    GoogleAnalytics(false);
}

function AbsolutelyNoCookies() {
    HideCookieNotice();
    GoogleAnalytics(false);
}


if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', HandleCookieConsent);
} else {
  HandleCookieConsent();
}
