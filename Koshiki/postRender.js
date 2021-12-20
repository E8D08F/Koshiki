[
    document.querySelector('g[data-mml-node="merror"]') ?
        document.querySelector('g[data-mml-node="merror"]').getAttribute("data-mjx-error") : '',
    document.querySelector('svg') ?
        [
            document.querySelector('svg').getBoundingClientRect().width,
            document.querySelector('svg').getBoundingClientRect().height,
            document.querySelector('svg').outerHTML.toString()
        ] : []
]
