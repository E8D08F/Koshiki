[
    document.querySelector('g[data-mml-node="merror"]') ?
        document.querySelector('g[data-mml-node="merror"]').getAttribute("data-mjx-error") : '',
    document.querySelector('#coloured svg') ?
        [
            document.querySelector('#coloured svg').getBoundingClientRect().width,
            document.querySelector('#coloured svg').getBoundingClientRect().height,
            document.querySelector('#coloured svg').outerHTML.toString(),
            document.querySelector('#original svg').outerHTML.toString()
        ] : []
]
