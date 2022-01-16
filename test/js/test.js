const eq = cs.asserts.eq
const neq = cs.asserts.neq
const contains = cs.asserts.contains
const fs = cs.files
const throws = cs.asserts.throws

cs.test('cs.asserts', () => {
    eq(1, 1)
    eq(0, 0)
    neq(0, false)
    neq(false, '')
})

cs.test('cs.files.readFile', () => {
    fs.writeFile('foo.dat', Uint8Array.from([1, 2, 3]))
    try {
        eq(fs.readFile('foo.dat'), Uint8Array.from([1, 2, 3]))
        eq(fs.readFile('bar.dat'), null)
    } finally {
        fs.removeFile('foo.dat')
    }
})

cs.test('cs.files.readTextFile', () => {
    fs.writeTextFile('foo.txt', 'foo')
    try {
        eq(fs.readTextFile('foo.txt'), 'foo')
        eq(fs.readTextFile('bar.txt'), null)
    } finally {
        fs.removeFile('foo.txt')
    }
})

cs.testIsolated('cs.files.readTextFileAsync', async () => {
    fs.writeTextFile('foo.txt', 'foo')
    try {
        let content = await fs.readTextFileAsync('foo.txt')
        eq(content, 'foo');
        content = await fs.readTextFileAsync('bar.txt')
        eq(content, null);
    } finally {
        fs.removeFile('foo.txt')
    }
})

cs.test('cs.files.writeFile', () => {
    eq(fs.writeFile('foo.dat', Uint8Array.from([1, 2, 3])), true)
    try {
        eq(fs.readFile('foo.dat'), Uint8Array.from([1, 2, 3]))
        eq(fs.writeFile('foo.dat', Uint8Array.from([4, 5, 6, 7])), true)
        // File is overwritten.
        eq(fs.readFile('foo.dat'), Uint8Array.from([4, 5, 6, 7]))
    } finally {
        fs.removeFile('foo.dat')
    }
})

cs.test('cs.files.writeTextFile', () => {
    eq(fs.writeTextFile('foo.txt', 'foo'), true)
    try {
        eq(fs.readTextFile('foo.txt'), 'foo')
        eq(fs.writeTextFile('foo.txt', 'bar'), true)
        // File is overwritten.
        eq(fs.readTextFile('foo.txt'), 'bar')
    } finally {
        fs.removeFile('foo.txt')
    }
})

cs.testIsolated('cs.files.writeTextFileAsync', async () => {
    eq(await fs.writeTextFileAsync('foo.txt', 'foo'), true);
    try {
        eq(fs.readTextFile('foo.txt'), 'foo')
        eq(await fs.writeTextFileAsync('foo.txt', 'bar'), true)
        // File is overwritten.
        eq(fs.readTextFile('foo.txt'), 'bar')
    } finally {
        fs.removeFile('foo.txt')
    }
})

cs.test('cs.files.appendTextFile', () => {
    eq(fs.appendTextFile('foo.txt', 'foo'), true)
    try {
        eq(fs.readTextFile('foo.txt'), 'foo')
        eq(fs.appendTextFile('foo.txt', 'bar'), true)
        eq(fs.readTextFile('foo.txt'), 'foobar')
    } finally {
        fs.removeFile('foo.txt')
    }
})

cs.testIsolated('cs.files.appendTextFileAsync', async () => {
    eq(await fs.appendTextFileAsync('foo.txt', 'foo'), true)
    try {
        eq(fs.readTextFile('foo.txt'), 'foo')
        eq(await fs.appendTextFileAsync('foo.txt', 'bar'), true)
        eq(fs.readTextFile('foo.txt'), 'foobar')
    } finally {
        fs.removeFile('foo.txt')
    }
})

cs.test('cs.files.removeFile', () => {
    eq(fs.removeFile('foo.txt'), false)
    fs.writeTextFile('foo.txt', 'foo');
    eq(fs.removeFile('foo.txt'), true);
})

cs.testIsolated('cs.files.removeFileAsync', async () => {
    eq(await fs.removeFileAsync('foo.txt'), false)
    fs.writeTextFile('foo.txt', 'foo');
    eq(await fs.removeFileAsync('foo.txt'), true);
})

cs.test('cs.files.removeDir', () => {
    eq(fs.pathExists('foo'), false)
    eq(fs.ensurePath('foo/bar', true), true)
    eq(fs.removeDir('foo', false), false)
    eq(fs.removeDir('foo/bar', false), true)
    eq(fs.ensurePath('foo/bar', true), true)
    eq(fs.removeDir('foo', true), true)
})

cs.testIsolated('cs.files.removeDirAsync', async () => {
    eq(fs.pathExists('foo'), false)
    eq(fs.ensurePath('foo/bar', true), true)
    eq(await fs.removeDirAsync('foo', false), false)
    eq(await fs.removeDirAsync('foo/bar', false), true)
    eq(fs.ensurePath('foo/bar', true), true)
    eq(await fs.removeDirAsync('foo', true), true)
})

cs.test('cs.files.ensurePath, cs.files.pathExists', () => {
    eq(fs.pathExists('foo/bar'), false)
    eq(fs.ensurePath('foo/bar'), true)
    try {
        eq(fs.pathExists('foo/bar'), true)
    } finally {
        eq(fs.removeDir('foo', true), true)
    }
})

cs.testIsolated('cs.files.ensurePathAsync, cs.files.pathExistsAsync', async () => {
    eq(await fs.pathExistsAsync('foo/bar'), false)
    eq(await fs.ensurePathAsync('foo/bar'), true)
    try {
        eq(await fs.pathExistsAsync('foo/bar'), true)
    } finally {
        eq(fs.removeDir('foo', true), true)
    }
})

cs.test('cs.files.resolvePath', () => {
    eq(fs.resolvePath('foo/../bar'), fs.resolvePath('bar'))
})

cs.test('cs.files.copyFile', () => {
    eq(fs.writeTextFile('foo.txt', 'foo'), true)
    try {
        eq(fs.readTextFile('bar.txt'), null)
        eq(fs.copyFile('foo.txt', 'bar.txt'), true)
        eq(fs.readTextFile('bar.txt'), 'foo')
        eq(fs.readTextFile('foo.txt'), 'foo')
    } finally {
        fs.removeFile('foo.txt')
        fs.removeFile('bar.txt')
    }
})

cs.testIsolated('cs.files.copyFileAsync', async () => {
    eq(fs.writeTextFile('foo.txt', 'foo'), true)
    try {
        eq(fs.readTextFile('bar.txt'), null)
        eq(await fs.copyFileAsync('foo.txt', 'bar.txt'), true)
        eq(fs.readTextFile('bar.txt'), 'foo')
        eq(fs.readTextFile('foo.txt'), 'foo')
    } finally {
        fs.removeFile('foo.txt')
        fs.removeFile('bar.txt')
    }
})

cs.test('cs.files.moveFile', () => {
    eq(fs.writeTextFile('foo.txt', 'foo'), true)
    try {
        eq(fs.readTextFile('bar.txt'), null)
        eq(fs.moveFile('foo.txt', 'bar.txt'), true)
        eq(fs.readTextFile('bar.txt'), 'foo')
        eq(fs.readTextFile('foo.txt'), null)
    } finally {
        fs.removeFile('foo.txt')
        fs.removeFile('bar.txt')
    }
})

cs.testIsolated('cs.files.moveFileAsync', async () => {
    eq(fs.writeTextFile('foo.txt', 'foo'), true)
    try {
        eq(fs.readTextFile('bar.txt'), null)
        eq(await fs.moveFileAsync('foo.txt', 'bar.txt'), true)
        eq(fs.readTextFile('bar.txt'), 'foo')
        eq(fs.readTextFile('foo.txt'), null)
    } finally {
        fs.removeFile('foo.txt')
        fs.removeFile('bar.txt')
    }
})

cs.test('cs.files.cwd', () => {
    eq(fs.cwd(), fs.resolvePath('.'));
})

cs.test('cs.files.getPathInfo', () => {
    eq(fs.getPathInfo('foo.txt'), null)
    eq(fs.writeTextFile('foo.txt', 'foo'), true)
    try {
        eq(fs.getPathInfo('foo.txt'), { kind: 'File' });
    } finally {
        fs.removeFile('foo.txt')
    }
})

cs.testIsolated('cs.files.getPathInfoAsync', async () => {
    eq(await fs.getPathInfoAsync('foo.txt'), null)
    eq(fs.writeTextFile('foo.txt', 'foo'), true)
    try {
        eq(await fs.getPathInfoAsync('foo.txt'), { kind: 'File' });
    } finally {
        fs.removeFile('foo.txt')
    }
})

cs.test('cs.files.listDir', () => {
    eq(fs.pathExists('foo/bar'), false)
    eq(fs.listDir('foo'), null)
    eq(fs.ensurePath('foo/bar'), true)
    try {
        eq(fs.writeTextFile('foo/foo.txt', 'foo'), true)
        eq(fs.listDir('foo'), [{ name: 'bar', kind: 'Directory' }, { name: 'foo.txt', kind: 'File' }]);
    } finally {
        fs.removeDir('foo', true)
    }
})

cs.testIsolated('cs.files.listDirAsync', async () => {
    eq(fs.pathExists('foo/bar'), false)
    eq(await fs.listDir('foo'), null)
    eq(fs.ensurePath('foo/bar'), true)
    try {
        eq(fs.writeTextFile('foo/foo.txt', 'foo'), true)
        eq(await fs.listDir('foo'), [{ name: 'bar', kind: 'Directory' }, { name: 'foo.txt', kind: 'File' }]);
    } finally {
        fs.removeDir('foo', true)
    }
})

cs.test('cs.files.walkDir', () => {
    eq(fs.pathExists('foo/bar'), false)
    eq(fs.walkDir('foo').next().done, true)
    eq(fs.ensurePath('foo/bar'), true)
    try {
        eq(fs.writeTextFile('foo/foo.txt', 'foo'), true)
        eq(fs.writeTextFile('foo/bar/bar.txt', 'bar'), true)
        const paths = []
        for (const e of fs.walkDir('foo')) {
            paths.push(e.path)
        }
        eq(paths, [
            'foo/bar',
            'foo/bar/bar.txt',
            'foo/foo.txt',
        ])
    } finally {
        fs.removeDir('foo', true)
    }
})

cs.testIsolated('cs.files.walkDirAsync', async () => {
    eq(fs.pathExists('foo/bar'), false)
    eq((await fs.walkDirAsync('foo').next()).done, true)
    eq(fs.ensurePath('foo/bar'), true)
    try {
        eq(fs.writeTextFile('foo/foo.txt', 'foo'), true)
        eq(fs.writeTextFile('foo/bar/bar.txt', 'bar'), true)
        const paths = []
        for await (const e of fs.walkDirAsync('foo')) {
            paths.push(e.path)
        }
        eq(paths, [
            'foo/bar',
            'foo/bar/bar.txt',
            'foo/foo.txt',
        ])
    } finally {
        fs.removeDir('foo', true)
    }
})

cs.test('cs.http.get', () => {
    let resp = cs.http.get('https://127.0.0.1')
    eq(resp, null)

    resp = cs.http.get('https://ziglang.org')
    contains(resp, 'Zig is a general-purpose programming language')
})

cs.test('cs.http.request', () => {
    throws(() => cs.http.request('https://127.0.0.1'), 'RequestFailed')

    const resp = cs.http.request('https://ziglang.org')
    eq(resp.status, 200)
    eq(resp.getHeader('content-type'), 'text/html')
    contains(resp.text(), 'Zig is a general-purpose programming language')
});

cs.testIsolated('cs.http.serveHttp', async () => {
    const s = cs.http.serveHttp('127.0.0.1', 3000)
    s.setHandler((req, resp) => {
        if (req.path == '/hello' && req.method == 'GET') {
            resp.setStatus(200)
            resp.setHeader('content-type', 'text/plain; charset=utf-8')
            resp.send('Hello from server!')
            return true
        } else if (req.path == '/hello' && req.method == 'POST') {
            var str = cs.util.bufferToUtf8(req.body)
            resp.setStatus(200)
            resp.setHeader('content-type', 'text/plain; charset=utf-8')
            resp.send(str)
            return true
        }
    })

    try {
        // Sync get won't work since it blocks and the server won't be able to accept.
        // However, async get should work.
        eq(await cs.http.getAsync('http://127.0.0.1:3000'), 'not found')
        let resp = await cs.http.requestAsync('http://127.0.0.1:3000/hello')
        eq(resp.status, 200)
        eq(resp.getHeader('content-type'), 'text/plain; charset=utf-8')
        eq(resp.text(), 'Hello from server!')

        // Post.
        eq(await cs.http.postAsync('http://127.0.0.1:3000/hello', 'my message'), 'my message')
    } finally {
        await s.closeAsync()
    }
    // return new Promise(() => {})
})

cs.testIsolated('cs.http.serveHttps', async () => {
    const s = cs.http.serveHttps('127.0.0.1', 3000, './vendor/https/localhost.crt', './vendor/https/localhost.key')
    s.setHandler((req, resp) => {
        if (req.path == '/hello' && req.method == 'GET') {
            resp.setStatus(200)
            resp.setHeader('content-type', 'text/plain; charset=utf-8')
            resp.send('Hello from server!')
            return true
        } else if (req.path == '/hello' && req.method == 'POST') {
            var str = cs.util.bufferToUtf8(req.body)
            resp.setStatus(200)
            resp.setHeader('content-type', 'text/plain; charset=utf-8')
            resp.send(str)
            return true
        }
    })

    try {
        // Sync get won't work since it blocks and the server won't be able to accept.
        // However, async get should work.
        // Needs self-signed certificate localhost.crt installed in cainfo or capath and the request needs to hit
        // localhost and not 127.0.0.1 for ssl verify host step to work.
        // TODO: Add request option to use specific ca certificate and option to turn off verify host.
        eq(await cs.http.getAsync('https://localhost:3000'), 'not found')
        const resp = await cs.http.requestAsync('https://localhost:3000/hello')
        eq(resp.status, 200)
        eq(resp.getHeader('content-type'), 'text/plain; charset=utf-8')
        eq(resp.text(), 'Hello from server!')

        // Post.
        eq(await cs.http.postAsync('https://localhost:3000/hello', 'my message'), 'my message')
    } finally {
        await s.closeAsync()
    }
    // return new Promise(() => {})
})