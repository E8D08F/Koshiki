let svg = document.querySelector('svg')
let rect = svg.getBoundingClientRect() 
let xml = new XMLSerializer().serializeToString(svg)
let svg64 = btoa(xml)
let src = 'data:image/svg+xml;base64,' + svg64
console.log(src)

let img = document.createElement('img')
img.src = src

// document.body.removeChild(svg)
// document.body.appendChild(img)

let canvas = document.createElement('canvas')
canvas.width = rect.width*2
canvas.height = rect.height*2
let ctx = canvas.getContext('2d')
ctx.drawImage(img, 0, 0)

let png = canvas.toDataURL('image/png')
