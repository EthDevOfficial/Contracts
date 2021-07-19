import BigNumber from "bignumber.js"
import { NUM_DECIMALS, ONE, QUAD_GRAPHS, SWAP_FEE_ACTUAL1, SWAP_FEE_ACTUAL2, TRI_GRAPHS } from "./constants"
import { getPostRatioDecrease, getPostRatioIncrease, inFromOut, inverse, linspace, outFromIn } from "./helpers"
import { outputForTargetMP } from "./moveToTarget"

const log = console.log

export function logSimpleTrade(
  title: string,
  in1: BigNumber, 
  out1in2: BigNumber, 
  out2: BigNumber,
  targetMP: BigNumber,
  postRatio1: BigNumber,
  postRatio2: BigNumber
) {
  if (!TRI_GRAPHS && !QUAD_GRAPHS) {
    log(title)
    log(`diff: ${out2.minus(in1).toFixed(NUM_DECIMALS)}`)
    log(`input: ${in1.toFixed(NUM_DECIMALS)}`)
    log(`middle: ${out1in2.toFixed(NUM_DECIMALS)}`)
    log(`output: ${out2.toFixed(NUM_DECIMALS)}`)
    log(`target MP: ${targetMP.toFixed(NUM_DECIMALS)}`)
    log(`ratio 1 post: ${postRatio1.toFixed(NUM_DECIMALS)}`)
    log(`ratio 2 post: ${postRatio2.toFixed(NUM_DECIMALS)}`)
    log()
  }
}

export function logSimpleTradeNoTarget(
  title: string,
  in1: BigNumber, 
  out1in2: BigNumber, 
  out2: BigNumber,
  R1a: BigNumber,
  R1b: BigNumber,
  R2a: BigNumber,
  R2b: BigNumber
) {
  if (!TRI_GRAPHS && !QUAD_GRAPHS) {
    log(title)
    log(`diff: ${out2.minus(in1).toFixed(NUM_DECIMALS)}`)
    log(`input: ${in1.toFixed(NUM_DECIMALS)}`)
    // log(`middle: ${out1in2.toFixed(NUM_DECIMALS)}`)
    // log(`output: ${out2.toFixed(NUM_DECIMALS)}`)
    log(`imbalance: ${getSimpleImbalance(
      R1a.plus(in1),
      R1b.minus(out1in2),
      R2a.minus(out2),
      R2b.plus(out1in2)
    ).toFixed(NUM_DECIMALS)}`)
    log()
  }
}

export function logSimpleTradeFrom1(
  R1a: BigNumber,
  R1b: BigNumber,
  R2a: BigNumber,
  R2b: BigNumber,
) {
  // gets the diff using optimal on 1st corner
  const avgMPab = getAvgMP(R1a, R1b, R2a, R2b)
  const out1in2 = outputForTargetMP(R1a, R1b, avgMPab, SWAP_FEE_ACTUAL1)
  const in1 = inFromOut(out1in2, R1a, R1b, SWAP_FEE_ACTUAL1)
  const out2 = outFromIn(out1in2, R2b, R2a, SWAP_FEE_ACTUAL2)
  logSimpleTrade(
    'Trade Using Corner 1',
    in1, out1in2, out2,
    avgMPab,
    getPostRatioIncrease(R1a, in1, R1b, out1in2),
    getPostRatioDecrease(R2a, out2, R2b, out1in2)
  )
  return in1
}

export function logSimpleTradeFrom1Double(
  R1a: BigNumber,
  R1b: BigNumber,
  R2a: BigNumber,
  R2b: BigNumber,
) {
  const _avgMPab = getAvgMP(R1a, R1b, R2a, R2b)
  const _out1in2 = outputForTargetMP(R1a, R1b, _avgMPab, SWAP_FEE_ACTUAL1)
  const _in1 = inFromOut(_out1in2, R1a, R1b, SWAP_FEE_ACTUAL1)
  const _out2 = outFromIn(_out1in2, R2b, R2a, SWAP_FEE_ACTUAL2)
  const avgMPab = getAvgMP(R1a.plus(_in1), R1b, R2a.minus(_out2), R2b)
  const out1in2 = outputForTargetMP(R1a, R1b, avgMPab, SWAP_FEE_ACTUAL1)
  const in1 = inFromOut(out1in2, R1a, R1b, SWAP_FEE_ACTUAL1)
  const out2 = outFromIn(out1in2, R2b, R2a, SWAP_FEE_ACTUAL2)
  logSimpleTrade(
    'Trade Using Corner 1 double',
    in1, out1in2, out2,
    avgMPab,
    getPostRatioIncrease(R1a, in1, R1b, out1in2),
    getPostRatioDecrease(R2a, out2, R2b, out1in2)
  )
  return in1
}

export function logSimpleTradeFrom2(
  R1a: BigNumber,
  R1b: BigNumber,
  R2a: BigNumber,
  R2b: BigNumber,
) {
  const avgMPab = getAvgMP(R1a, R1b, R2a, R2b)
  const out2 = outputForTargetMP(R2b, R2a, inverse(avgMPab), SWAP_FEE_ACTUAL2)
  const out1in2 = inFromOut(out2, R2b, R2a, SWAP_FEE_ACTUAL2)
  const in1 = inFromOut(out1in2, R1a, R1b, SWAP_FEE_ACTUAL1)
  logSimpleTrade(
    'Trade Using Corner 2',
    in1, out1in2, out2,
    avgMPab,
    getPostRatioIncrease(R1a, in1, R1b, out1in2),
    getPostRatioDecrease(R2a, out2, R2b, out1in2)
  )
  return in1
}

export function logSimpleTradeFrom2Double(
  R1a: BigNumber,
  R1b: BigNumber,
  R2a: BigNumber,
  R2b: BigNumber,
) {
  const _avgMPab = getAvgMP(R1a, R1b, R2a, R2b)
  const _out2 = outputForTargetMP(R2b, R2a, inverse(_avgMPab), SWAP_FEE_ACTUAL2)
  const _out1in2 = inFromOut(_out2, R2b, R2a, SWAP_FEE_ACTUAL2)
  const _in1 = inFromOut(_out1in2, R1a, R1b, SWAP_FEE_ACTUAL1)
  const avgMPab = getAvgMP(R1a.plus(_in1), R1b, R2a.minus(_out2), R2b)
  const out2 = outputForTargetMP(R2b, R2a, inverse(avgMPab), SWAP_FEE_ACTUAL2)
  const out1in2 = inFromOut(out2, R2b, R2a, SWAP_FEE_ACTUAL2)
  const in1 = inFromOut(out1in2, R1a, R1b, SWAP_FEE_ACTUAL1)
  logSimpleTrade(
    'Trade Using Corner 2 double',
    in1, out1in2, out2,
    avgMPab,
    getPostRatioIncrease(R1a, in1, R1b, out1in2),
    getPostRatioDecrease(R2a, out2, R2b, out1in2)
  )
  return in1
}

export function logSimpleTradeChooseCorner(
  R1a: BigNumber,
  R1b: BigNumber,
  R2a: BigNumber,
  R2b: BigNumber
) {
  if (R1a.isLessThan(R1b)) {
    return logSimpleTradeFrom1(R1a, R1b, R2a, R2b)
  } else {
    return logSimpleTradeFrom2(R1a, R1b, R2a, R2b)
  }
}

export function logSimpleTradeFromIn(
  title: string,
  input: BigNumber,
  R1a: BigNumber,
  R1b: BigNumber,
  R2a: BigNumber,
  R2b: BigNumber,
) {
  const out1in2 = outFromIn(input, R1a, R1b, SWAP_FEE_ACTUAL1)
  const output = outFromIn(out1in2, R2b, R2a, SWAP_FEE_ACTUAL2)
  logSimpleTradeNoTarget(
    title,
    input, out1in2, output,
    R1a, R1b, R2a, R2b
  )
  return output.minus(input)
}

export function getSimpleTradeFromIn(
  input: BigNumber,
  R1a: BigNumber,
  R1b: BigNumber,
  R2a: BigNumber,
  R2b: BigNumber,
  reducer = 1
) {
  const out1in2 = outFromIn(input, R1a, R1b, SWAP_FEE_ACTUAL1)
  const output = outFromIn(out1in2, R2b, R2a, SWAP_FEE_ACTUAL2)
  return {
    input: Math.floor(input.dividedBy(reducer).toNumber()),
    diff: Math.floor(output.minus(input).dividedBy(reducer).toNumber()),
    imbalance: getSimpleImbalance(
      R1a.plus(input),
      R1b.minus(out1in2),
      R2a.minus(output),
      R2b.plus(out1in2)
    ).toNumber()
  }
}

export function getSimpleTradeLineFromInputRange(
  range: [BigNumber, BigNumber],
  length: number,
  reducer: number,
  R1a: BigNumber,
  R1b: BigNumber,
  R2a: BigNumber,
  R2b: BigNumber
) {
  const line = linspace(
    range[0].dividedBy(reducer).toNumber(),
    range[1].dividedBy(reducer).toNumber(),
    length 
  )
  return line.map(inputPreMul => getSimpleTradeFromIn(
    new BigNumber(inputPreMul).multipliedBy(reducer),
    R1a, R1b, R2a, R2b
  ))
}

export function getSimpleImbalanceSub(
  R1a: BigNumber, R1b: BigNumber,
  R2a: BigNumber, R2b: BigNumber
) {
  return R2a.dividedBy(R2b).minus(R1a.dividedBy(R1b))
}

export function getSimpleImbalance(
  R1a: BigNumber, R1b: BigNumber,
  R2a: BigNumber, R2b: BigNumber
) {
  return R2a.multipliedBy(R1b).dividedBy(R1a.multipliedBy(R2b)).minus(1)
}

export function getInputMultiplier(
  R1a: BigNumber, R1b: BigNumber,
  R2a: BigNumber, R2b: BigNumber
) {
  return ONE.minus(ONE.minus(SWAP_FEE_ACTUAL1).plus(ONE.minus(SWAP_FEE_ACTUAL2)).dividedBy(getSimpleImbalance(R1a, R1b, R2a, R2b)))
}

export function getAvgMP(
  R1a: BigNumber,
  R1b: BigNumber,
  R2a: BigNumber,
  R2b: BigNumber
) {
  return R1a.plus(R2a).dividedBy(R1b.plus(R2b))
}

export function logRatios(
  R1a: BigNumber,
  R1b: BigNumber,
  R2a: BigNumber,
  R2b: BigNumber
) {
  console.log(`ratio 1: ${R1a.dividedBy(R1b).toFixed(NUM_DECIMALS)}`)
  console.log(`ratio 2: ${R2a.dividedBy(R2b).toFixed(NUM_DECIMALS)}`)
}