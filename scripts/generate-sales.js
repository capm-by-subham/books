#!/usr/bin/env node
// Generates realistic sample sales for the Analytical List Page (app/book-sales-alp).
//
//   node scripts/generate-sales.js            -> writes db/data/my.bookshop-BookSales.csv
//   node scripts/generate-sales.js --seed 7   -> different (but again repeatable) data
//
// Same seed = same file, so the numbers in ALP_GUIDE.md stay valid. cds watch picks up the new CSV
// automatically (in-memory database is reloaded on restart).
//
// Built-in patterns, so the charts have something to show:
//   - seasonality: sales peak in Q4 (Christmas), dip in summer
//   - growth: 2026 has ~10% more sales than 2025
//   - Online grows from 2025 to 2026, Store shrinks
//   - West is the strongest region, East the smallest
//   - Partner sells in bulk with high discounts -> thin margin, usually below target
//   - classics (The Raven, Jane Eyre, Wuthering Heights) sell more than the rest

const fs = require('fs')
const path = require('path')

const seedArg = process.argv.indexOf('--seed')
let seed = seedArg > 0 ? Number(process.argv[seedArg + 1]) : 42

// small seeded random number generator (mulberry32): same seed -> same sequence
const rand = () => {
  seed |= 0; seed = (seed + 0x6d2b79f5) | 0
  let t = Math.imul(seed ^ (seed >>> 15), 1 | seed)
  t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t
  return ((t ^ (t >>> 14)) >>> 0) / 4294967296
}
const between = (min, max) => min + rand() * (max - min)
const pick = weights => { // { key: weight } -> key
  const total = Object.values(weights).reduce((a, b) => a + b, 0)
  let r = rand() * total
  for (const [key, w] of Object.entries(weights)) if ((r -= w) < 0) return key
  return Object.keys(weights).at(-1)
}
const round2 = n => Math.round(n * 100) / 100
const uuid = () => 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, c => {
  const r = Math.floor(rand() * 16)
  return (c === 'x' ? r : (r & 0x3) | 0x8).toString(16)
})

// books and their list prices come from the Books CSV, converted to EUR (reporting currency)
const data = path.join(__dirname, '..', 'db', 'data')
const [header, ...rows] = fs.readFileSync(path.join(data, 'my.bookshop-Books.csv'), 'utf8').trim().split('\n')
const cols = header.split(';')
const toEUR = { EUR: 1, GBP: 1.17, USD: 0.92 }
const books = rows.map(line => {
  const r = Object.fromEntries(line.split(';').map((v, i) => [cols[i], v]))
  return { ID: r.ID, title: r.title, priceEUR: Number(r.price) * (toEUR[r.currency_code] ?? 1) }
})
const bookWeights = Object.fromEntries(books.map(b => [b.ID, 1]))
Object.assign(bookWeights, { 1: 3, 2: 3, 3: 4, 5: 0.15, 8: 2 }) // classics sell more, expensive Catweazle less

const regions = { W: 35, N: 22, S: 23, E: 20 }
const countries = {
  N: ['Sweden', 'Norway', 'Denmark', 'Finland'],
  S: ['Spain', 'Italy', 'Portugal', 'Greece'],
  E: ['Poland', 'Czechia', 'Hungary', 'Romania'],
  W: ['United Kingdom', 'Ireland', 'France', 'Netherlands', 'Belgium']
}
const channels = { 2025: { ONL: 35, STO: 40, PAR: 25 }, 2026: { ONL: 50, STO: 30, PAR: 20 } }
const seasonality = [0.8, 0.75, 0.85, 0.9, 0.9, 0.8, 0.75, 0.8, 0.95, 1.1, 1.35, 1.65] // Jan..Dec
const growth = { 2025: 1, 2026: 1.1 }
const linesPerMonth = 20

const out = ['ID;book_ID;saleDate;region_code;country;channel_code;quantity;revenue;currency_code;discount;cost;target']
for (const year of [2025, 2026]) {
  const lastMonth = year === 2026 ? 9 : 12 // data until end of September 2026
  for (let month = 1; month <= lastMonth; month++) {
    const count = Math.round(linesPerMonth * seasonality[month - 1] * growth[year] * between(0.9, 1.1))
    for (let i = 0; i < count; i++) {
      const bookID = pick(bookWeights)
      const book = books.find(b => b.ID === bookID)
      const region = pick(regions)
      const channel = pick(channels[year])
      const quantity = 1 + Math.floor(rand() * ({ ONL: 4, STO: 6, PAR: 20 }[channel]))
      const discount = round2({ ONL: between(0, 10), STO: between(0, 5), PAR: between(10, 25) }[channel])
      const listValue = quantity * book.priceEUR
      const revenue = round2(listValue * (1 - discount / 100))
      const cost = round2(listValue * between(0.45, 0.62))
      const target = round2(listValue * between(0.86, 0.94)) // so roughly: discount > ~10% -> below target
      const day = String(1 + Math.floor(rand() * 28)).padStart(2, '0')
      const saleDate = `${year}-${String(month).padStart(2, '0')}-${day}`
      const country = countries[region][Math.floor(rand() * countries[region].length)]
      out.push([uuid(), book.ID, saleDate, region, country, channel, quantity, revenue, 'EUR', discount, cost, target].join(';'))
    }
  }
}

const file = path.join(data, 'my.bookshop-BookSales.csv')
fs.writeFileSync(file, out.join('\n') + '\n')
console.log(`wrote ${out.length - 1} sales to ${path.relative(process.cwd(), file)}`)
