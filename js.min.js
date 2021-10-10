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

