import BigNumber from "bignumber.js";
import { ONE, SWAP_FEE_ACTUAL1, SWAP_FEE_ACTUAL2, SWAP_FEE_ACTUAL3, SWAP_FEE_TRI_SUM, TRI_GRAPHS } from "./constants";
import { outFromIn, sumOf } from "./helpers";
import { getTriImbalance, logTriTradeFromIn } from "./triHelpers";

export function logTriTradeIterator(
  R1a: BigNumber,
  R1b: BigNumber,
  R2b: BigNumber,
  R2c: BigNumber,
  R3c: BigNumber,
  R3a: BigNumber,
  initInputStepDivisor: BigNumber,
  maxIterations: number,
  threshold: BigNumber,
  targetPlus = new BigNumber(0),
  exactInitInputStep?: BigNumber
) {
  const initImbalance = getTriImbalance(R1a, R1b, R2b, R2c, R3c, R3a)
  let inputStep = exactInitInputStep ? exactInitInputStep : R1a.dividedBy(initInputStepDivisor)
  let out1in2Step = outFromIn(inputStep, R1a, R1b, SWAP_FEE_ACTUAL1)
  let out2in3Step = outFromIn(out1in2Step, R2b, R2c, SWAP_FEE_ACTUAL2)
  let outputStep = outFromIn(out2in3Step, R3c, R3a, SWAP_FEE_ACTUAL3)
  let postStepImbalance = getTriImbalance(
    R1a.plus(inputStep),
    R1b.minus(out1in2Step),
    R2b.plus(out1in2Step),
    R2c.minus(out2in3Step),
    R3c.plus(out2in3Step),
    R3a.minus(outputStep)
  )
  for (let i = 0; i < maxIterations; i++) {
    inputStep = initImbalance.minus(SWAP_FEE_TRI_SUM.plus(targetPlus)).multipliedBy(inputStep.dividedBy(initImbalance.minus(postStepImbalance)))
    out1in2Step = outFromIn(inputStep, R1a, R1b, SWAP_FEE_ACTUAL1)
    out2in3Step = outFromIn(out1in2Step, R2b, R2c, SWAP_FEE_ACTUAL2)
    outputStep = outFromIn(out2in3Step, R3c, R3a, SWAP_FEE_ACTUAL3)
    postStepImbalance = getTriImbalance(
      R1a.plus(inputStep),
      R1b.minus(out1in2Step),
      R2b.plus(out1in2Step),
      R2c.minus(out2in3Step),
      R3c.plus(out2in3Step),
      R3a.minus(outputStep)
    )
    if (postStepImbalance.minus(SWAP_FEE_TRI_SUM.plus(targetPlus)).absoluteValue().isLessThan(threshold)) {
      logTriTradeFromIn('iterative formula tri trade', inputStep, R1a, R1b, R2b, R2c, R3c, R3a)
      if (TRI_GRAPHS) console.log(`number of iterations: ${i + 1}`)
      return inputStep
    }
  }
  logTriTradeFromIn('iterative formula tri trade', inputStep, R1a, R1b, R2b, R2c, R3c, R3a)
  if (TRI_GRAPHS) console.log(`number of iterations (max): ${maxIterations}`)
  return inputStep
}

export function logTriTradeLowImbalance(
  R1a: BigNumber,
  R1b: BigNumber,
  R2b: BigNumber,
  R2c: BigNumber,
  R3c: BigNumber,
  R3a: BigNumber,
  inputStepDivisor: BigNumber,
  exactInputStep?: BigNumber
) {
  const inputStep = exactInputStep ? exactInputStep : R1a.dividedBy(inputStepDivisor)
  const out1in2Step = outFromIn(inputStep, R1a, R1b, SWAP_FEE_ACTUAL1)
  const out2in3Step = outFromIn(out1in2Step, R2b, R2c, SWAP_FEE_ACTUAL2)
  const outputStep = outFromIn(out2in3Step, R3c, R3a, SWAP_FEE_ACTUAL3)
  const initImbalance = getTriImbalance(R1a, R1b, R2b, R2c, R3c, R3a)
  const postStepImbalance = getTriImbalance(
    R1a.plus(inputStep),
    R1b.minus(out1in2Step),
    R2b.plus(out1in2Step),
    R2c.minus(out2in3Step),
    R3c.plus(out2in3Step),
    R3a.minus(outputStep)
  )
  const input = initImbalance.minus(sumOf(ONE.minus(SWAP_FEE_ACTUAL1), ONE.minus(SWAP_FEE_ACTUAL2), ONE.minus(SWAP_FEE_ACTUAL3)))
    .multipliedBy(inputStep.dividedBy(initImbalance.minus(postStepImbalance)))
  logTriTradeFromIn('low imbalance formula tri trade', input, R1a, R1b, R2b, R2c, R3c, R3a)
  return input
}