import { expect as want } from 'chai'

import { ethers } from 'hardhat'

import { b32, wad, ray, send } from './helpers'
import * as hh from "hardhat"
const dpack = require('dpack')
const debug = require('debug')('rico:test')

const ZERO = Buffer.alloc(32)
const i0 = ZERO // ilk 0 id

const TAG = Buffer.from('feed'.repeat(16), 'hex')

describe('plot vat ilk mark via plotter', () => {
  let ali, bob, cat
  let ALI, BOB, CAT
  let vat
  let plotter
  let fb
  let dapp
  before(async () => {
    [ali, bob, cat] = await ethers.getSigners();
    [ALI, BOB, CAT] = [ali, bob, cat].map(signer => signer.address)
    const pack = await hh.run('deploy-ricobank', { mock: 'true' })
    dapp = await dpack.Dapp.loadFromPack(pack, ali, ethers)
  })
  beforeEach(async () => {
    vat = dapp.objects.vat
    plotter = dapp.objects.plotter
    fb = dapp.objects.feedbase

    await send(vat.ward, plotter.address, true)

    await send(plotter.link, b32("fb"), fb.address)
    await send(plotter.link, b32("vat"), vat.address)
    await send(plotter.link, b32("tip"), ALI)

    await send(plotter.wire, i0, TAG)
  })

  it('plot mark', async () => {
    const p = Buffer.from(wad(1200).toHexString().slice(2).padStart(64, '0'), 'hex')
    await send(fb.push, TAG, p, 10 ** 10)
    await send(plotter.poke, i0)

    const [,,mark0] = await vat.ilks(i0)
    want(mark0.eq(ray(1200))).true // upcast to ray by plotter
  })
})
