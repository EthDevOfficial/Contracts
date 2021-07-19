import BigNumber from "bignumber.js";
import { NUM_DECIMALS, QUAD_GRAPHS, SWAP_FEE_ACTUAL1, SWAP_FEE_ACTUAL2, SWAP_FEE_ACTUAL3, SWAP_FEE_ACTUAL4, SWAP_FEE_QUAD_SUM } from "./constants";
import { linspace, outFromIn, productOf } from "./helpers";

const log = console.log

export function logQuadTradeIterator(
  R1a: BigNumber,
  R1b: BigNumber,
  R2b: BigNumber,
  R2c: BigNumber,
  R3c: BigNumber,
  R3d: BigNumber,
  R4d: BigNumber,
  R4a: BigNumber,
  initInputStepDivisor: BigNumber,
  maxIterations: number,
  threshold: BigNumber,
  targetPlus = new BigNumber(0),
  exactInitInputStep?: BigNumber
) {
  const initImbalance = getQuadImbalance(R1a, R1b, R2b, R2c, R3c, R3d, R4d, R4a)
  let inputStep = exactInitInputStep ? exactInitInputStep : R1a.dividedBy(initInputStepDivisor)
  let out1in2Step = outFromIn(inputStep, R1a, R1b, SWAP_FEE_ACTUAL1)
  let out2in3Step = outFromIn(out1in2Step, R2b, R2c, SWAP_FEE_ACTUAL2)
  let out3in4Step = outFromIn(out2in3Step, R3c, R3d, SWAP_FEE_ACTUAL3)
  let outputStep = outFromIn(out3in4Step, R4d, R4a, SWAP_FEE_ACTUAL4)
  let postStepImbalance = getQuadImbalance(
    R1a.plus(inputStep),
    R1b.minus(out1in2Step),
    R2b.plus(out1in2Step),
    R2c.minus(out2in3Step),
    R3c.plus(out2in3Step),
    R3d.minus(out3in4Step),
    R4d.plus(out3in4Step),
    R4a.minus(outputStep)
  )
  for (let i = 0; i < maxIterations; i++) {
    inputStep = initImbalance.minus(SWAP_FEE_QUAD_SUM.plus(targetPlus)).multipliedBy(inputStep.dividedBy(initImbalance.minus(postStepImbalance)))
    out1in2Step = outFromIn(inputStep, R1a, R1b, SWAP_FEE_ACTUAL1)
    out2in3Step = outFromIn(out1in2Step, R2b, R2c, SWAP_FEE_ACTUAL2)
    out3in4Step = outFromIn(out2in3Step, R3c, R3d, SWAP_FEE_ACTUAL3)
    outputStep = outFromIn(out3in4Step, R4d, R4a, SWAP_FEE_ACTUAL4)
    postStepImbalance = getQuadImbalance(
      R1a.plus(inputStep),
      R1b.minus(out1in2Step),
      R2b.plus(out1in2Step),
      R2c.minus(out2in3Step),
      R3c.plus(out2in3Step),
      R3d.minus(out3in4Step),
      R4d.plus(out3in4Step),
      R4a.minus(outputStep)
    )
    if (postStepImbalance.minus(SWAP_FEE_QUAD_SUM.plus(targetPlus)).absoluteValue().isLessThan(threshold)) {
      logQuadTradeFromIn('iterative formula quad trade', inputStep, R1a, R1b, R2b, R2c, R3c, R3d, R4d, R4a)
      if (QUAD_GRAPHS) console.log(`number of iterations: ${i + 1}`)
      return inputStep
    }
  }
  logQuadTradeFromIn('iterative formula tri trade', inputStep, R1a, R1b, R2b, R2c, R3c, R3d, R4d, R4a)
  if (QUAD_GRAPHS) console.log(`number of iterations (max): ${maxIterations}`)
  return inputStep
}

export function getQuadImbalance(
  R1a: BigNumber,
  R1b: BigNumber,
  R2b: BigNumber,
  R2c: BigNumber,
  R3c: BigNumber,
  R3d: BigNumber,
  R4d: BigNumber,
  R4a: BigNumber,
) {
  const MPba = R1b.dividedBy(R1a)
  const MPcb = R2c.dividedBy(R2b)
  const MPdc = R3d.dividedBy(R3c)
  const MPad = R4a.dividedBy(R4d)
  return productOf(MPba, MPcb, MPdc, MPad).minus(1)
}

function getQuadTradeFromIn(
  input: BigNumber,
  R1a: BigNumber,
  R1b: BigNumber,
  R2b: BigNumber,
  R2c: BigNumber,
  R3c: BigNumber,
  R3d: BigNumber,
  R4d: BigNumber,
  R4a: BigNumber,
  reducer = 1
) {
  const out1in2 = outFromIn(input, R1a, R1b, SWAP_FEE_ACTUAL1)
  const out2in3 = outFromIn(out1in2, R2b, R2c, SWAP_FEE_ACTUAL2)
  const out3in4 = outFromIn(out2in3, R3c, R3d, SWAP_FEE_ACTUAL3)
  const output = outFromIn(out3in4, R4d, R4a, SWAP_FEE_ACTUAL4)
  return {
    input: Math.floor(input.dividedBy(reducer).toNumber()),
    diff: Math.floor(output.minus(input).dividedBy(reducer).toNumber()),
    imbalance: getQuadImbalance(
      R1a.plus(input),
      R1b.minus(out1in2),
      R2b.plus(out1in2),
      R2c.minus(out2in3),
      R3c.plus(out2in3),
      R3d.minus(out3in4),
      R4d.plus(out3in4),
      R4a.minus(output)
    ).toNumber(),
  }
}

export function getQuadTradeLineFromInputRange(
  range: [BigNumber, BigNumber],
  length: number,
  reducer: number,
  R1a: BigNumber,
  R1b: BigNumber,
  R2b: BigNumber,
  R2c: BigNumber,
  R3c: BigNumber,
  R3d: BigNumber,
  R4d: BigNumber,
  R4a: BigNumber,
) {
  const line = linspace(
    range[0].dividedBy(reducer).toNumber(),
    range[1].dividedBy(reducer).toNumber(),
    length 
  )
  return line.map(inputPreMul => getQuadTradeFromIn(
    new BigNumber(inputPreMul).multipliedBy(reducer),
    R1a, R1b, R2b, R2c, R3c, R3d, R4d, R4a
  ))
}

export function logQuadTradeFromIn(
  title: string,
  input: BigNumber,
  R1a: BigNumber,
  R1b: BigNumber,
  R2b: BigNumber,
  R2c: BigNumber,
  R3c: BigNumber,
  R3d: BigNumber,
  R4d: BigNumber,
  R4a: BigNumber
) {
  const out1in2 = outFromIn(input, R1a, R1b, SWAP_FEE_ACTUAL1)
  const out2in3 = outFromIn(out1in2, R2b, R2c, SWAP_FEE_ACTUAL2)
  const out3in4 = outFromIn(out2in3, R3c, R3d, SWAP_FEE_ACTUAL3)
  const output = outFromIn(out3in4, R4d, R4a, SWAP_FEE_ACTUAL4)
  logQuadTrade(
    title,
    input, out1in2, out2in3, out3in4, output,
    R1a.plus(input),
    R1b.minus(out1in2),
    R2b.plus(out1in2),
    R2c.minus(out2in3),
    R3c.plus(out2in3),
    R3d.minus(out3in4),
    R4d.plus(out3in4),
    R4a.minus(output)
  )
  return output.minus(input)
}

export function logQuadTrade(
  title: string,
  input: BigNumber,
  out1in2: BigNumber,
  out2in3: BigNumber,
  out3in4: BigNumber,
  output: BigNumber,
  R1aPost: BigNumber,
  R1bPost: BigNumber,
  R2bPost: BigNumber,
  R2cPost: BigNumber,
  R3cPost: BigNumber,
  R3dPost: BigNumber,
  R4dPost: BigNumber,
  R4aPost: BigNumber
) {
  if (QUAD_GRAPHS) {
    log(title)
    log(`diff: ${output.minus(input).toFixed(NUM_DECIMALS)}`)
    log(`input: ${input.toFixed(NUM_DECIMALS)}`)
    // log(`out 1 in 2: ${out1in2.toFixed(NUM_DECIMALS)}`)
    // log(`out 2 in 3: ${out2in3.toFixed(NUM_DECIMALS)}`)
    log(`imbalance: ${getQuadImbalance(R1aPost, R1bPost, R2bPost, R2cPost, R3cPost, R3dPost, R4dPost, R4aPost).toFixed(NUM_DECIMALS)}`)
    log()
  }
}