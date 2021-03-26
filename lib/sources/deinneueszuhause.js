const FlatFinder = require('lib/flatfinder')
const config = require('conf/config.json')
const utils = require('lib/utils')

function normalize(o) {
console.log(o)
  const id = parseInt(o.id.split('_')[1], 10)
  const address = o.address ? o.address.split(' • ')[2] : ''
  const rooms = o.rooms + ' Zimmer'

  return Object.assign(o, { id, title, address, rooms })
}

function applyBlacklist(o) {
  const titleNotBlacklisted = !utils.isOneOf(o.title, config.blacklist)
  const descNotBlacklisted = !utils.isOneOf(o.description, config.blacklist)
  const wantedDistrict = utils.isOneOf(o.description, config.wantedDistricts)
  return wantedDistrict && titleNotBlacklisted && descNotBlacklisted
}

const enabled = !!config.providers.deinneueszuhause

const deinneueszuhause = {
  name: 'deinneueszuhause',
  enabled,
  url: !enabled || config.providers.deinneueszuhause.url,
  crawlContainer: '.Search__results___dnz .row .col',
  crawlFields: {
    id: 'div[onclick^=try] a@id | trim',
    price: '.property__data-entry:nth-child(1) .property__data-value | int',
    size: 'property__data-entry:nth-child(2) .property__data-value | trim | int',
    title: '.property__location a | removeNewline | trim',
    link: 'div[onclick^=try] a@href',
    address: '.property__location a | removeNewline | trim',
    rooms: 'property__data-entry:nth-child(3) .property__data-value',
  },
  paginate: '.pagination-wrapper + a@href',
  normalize: normalize,
  filter: applyBlacklist,
}

module.exports = new FlatFinder(deinneueszuhause)
