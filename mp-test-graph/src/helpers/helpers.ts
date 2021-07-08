import BigNumber from "bignumber.js"
import { ONE } from "./constants"

export function inverse(bn: BigNumber) {
  return ONE.dividedBy(bn)
}

export function sumOf(...bnArray: BigNumber[]) {
  return bnArray.reduce((prev, curr) => curr.plus(prev))
}

export function productOf(...bnArray: BigNumber[]) {
  return bnArray.reduce((prev, curr) => curr.multipliedBy(prev))
}

export function squared(bn: BigNumber) {
  return bn.multipliedBy(bn)
}

export function outFromIn(
  amountIn: BigNumber,
  Rin: BigNumber,
  Rout: BigNumber,
  swapFee: BigNumber
) {
  const numerator = Rin.multipliedBy(Rout)
  const denom = Rin.plus(swapFee.multipliedBy(amountIn))
  return Rout.minus(numerator.dividedBy(denom))
}

export function inFromOut(
  amountOut: BigNumber,
  Rin: BigNumber,
  Rout: BigNumber,
  swapFee: BigNumber
) {
  const numerator = Rin.multipliedBy(Rout)
  const denom = Rout.minus(amountOut)
  const multiplier = numerator.dividedBy(denom).minus(Rin)
  return ONE.dividedBy(swapFee).multipliedBy(multiplier)
}

export function getPostRatioIncrease(
  R1: BigNumber, dR1: BigNumber, // plus
  R2: BigNumber, dR2: BigNumber // minus
) {
  return R1.plus(dR1).dividedBy(R2.minus(dR2))
}

export function getPostRatioDecrease(
  R1: BigNumber, dR1: BigNumber, // minus
  R2: BigNumber, dR2: BigNumber // plus
) {
  return R1.minus(dR1).dividedBy(R2.plus(dR2))
}

export function getOptimal(
  Rin: BigNumber,
  Rout: BigNumber,
  targetMP: BigNumber,
  swapFee: BigNumber
) {
  const numerator = Rin.multipliedBy(Rout).squareRoot()
  const denom = targetMP.multipliedBy(swapFee).squareRoot()
  return Rout.minus(numerator.dividedBy(denom))
}

/**
 * @param start start of array (inclusive)
 * @param stop end of array (inclusive)
 * @param length number of entries in array
 * @returns Array of integers from start to stop.
 * if start >= stop, returns empty array
 */
export function linspace(start: number, stop: number, length: number) {
  const line: number[] = []
  const step = (stop - start) / (length - 1)
  for (let i = 0; i < length; i++) {
    line[i] = start + i * step
  }
  return line
}