import BigNumber from "bignumber.js"
import { productOf, sumOf } from "./helpers"
import { quadraticSolPos } from "./quadratics"

const TWO = new BigNumber(2)

export function outputForTargetMP(
  Rin: BigNumber, 
  Rout: BigNumber,
  targetMP: BigNumber, // in on top
  swapFee: BigNumber
) {
  const a = swapFee.multipliedBy(targetMP).negated()
  const b = sumOf(Rin, productOf(TWO, swapFee, targetMP, Rout), swapFee.multipliedBy(Rin).negated())
  const c = productOf(swapFee, Rout, Rin.minus(targetMP.multipliedBy(Rout)))
  return quadraticSolPos(a, b, c)
}