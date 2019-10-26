function CookieGetBlock() {
    return '';
}
function StorageGetBlock() {
    return undefined;
}
function CookieSetBlock() {}
function StorageSetBlock() {}
if (!document.__defineGetter__) {
    Object.defineProperty(document, 'cookie', {
        get: CookieGetBlock,
        set: CookieSetBlock,
    });
} else {
    document.__defineGetter__("cookie", CookieGetBlock);
    document.__defineSetter__("cookie", CookieSetBlock);
}
if (!window.__defineGetter__) {
    Object.defineProperty(window, 'localStorage', {
        get: StorageGetBlock,
        set: StorageSetBlock,
    });
    Object.defineProperty(window, 'sessionStorage', {
        get: StorageGetBlock,
        set: StorageSetBlock,
    });
} else {
    window.__defineGetter__("localStorage", StorageGetBlock);
    window.__defineGetter__("sessionStorage", StorageGetBlock);
    window.__defineSetter__("localStorage", StorageSetBlock);
    window.__defineSetter__("sessionStorage", StorageSetBlock);
}

// analytics.js
(function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
    (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
                         m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
                        })(window,document,'script','https://www.google-analytics.com/analytics.js','ga');


ga('create', 'UA-34701218-2', 'auto' , {
    'storage': 'none',
    'storeGac': false,
    'clientId': Math.random().toString()
});
ga(function(tracker) {
    console.log(tracker.get('clientId'));
});
ga('set', 'allowAdFeatures', false);
ga('set', 'anonymizeIp', true);
ga('send', 'pageview');
ga('send', 'pageview', {'sessionControl': 'end'});
ga('remove');
