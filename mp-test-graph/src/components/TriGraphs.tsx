import BigNumber from "bignumber.js"
import { Fragment } from "react"
import { NUM_DECIMALS, TRI_GRAPHS } from "../helpers/constants"
import { productOf } from "../helpers/helpers"
import { getTriImbalance, getTriTradeLineFromInputRange } from "../helpers/triHelpers"
import { logTriTradeIterator } from "../helpers/triHelpersLowImb"
import Graph from './Graph'

const IMBALANCE = .0092

const R1a = new BigNumber('3867048069836398061306')
const R1b = new BigNumber('57460840958119358875174')

const R2b = new BigNumber('43802000426928227643118')
const R2c = new BigNumber('30213060077310057203')

const R3c = new BigNumber('2191250871510594310478')
// const R3a = productOf(R1a.dividedBy(R1b), R2b.dividedBy(R2c), new BigNumber(1 + IMBALANCE), R3c)
const R3a = new BigNumber('769469043381144633661947')

if (TRI_GRAPHS) console.log(`init imbalance: ${getTriImbalance(R1a, R1b, R2b, R2c, R3c, R3a).toFixed(NUM_DECIMALS)}`)

const inputStepDivisor = new BigNumber('100000')
const CLOSENESS_THRESHOLD = new BigNumber('.00005')
const RANGE_MULTIPLIER = 1

const MAX_ITERATIONS = 7
const inputFromIterator = logTriTradeIterator(
  R1a, R1b, R2b, R2c, R3c, R3a,
  inputStepDivisor, 
  MAX_ITERATIONS,
  CLOSENESS_THRESHOLD,
  new BigNumber('0.000054')
)

const data2 = getTriTradeLineFromInputRange(
  [
    inputFromIterator.minus(inputFromIterator.multipliedBy(RANGE_MULTIPLIER)), 
    inputFromIterator.plus(inputFromIterator.multipliedBy(RANGE_MULTIPLIER))
  ], // range
  100,  // number of values (resolution)
  100000, // divisor to convert BN to normal numbers
  R1a, R1b, R2b, R2c, R3c, R3a
)

function TriGraphs() {
  return (
    <Fragment>
      {/* <Graph
        title='diff from 1 step' 
        data={data1}
        lineDataKey="diff"
        xAxisDataKey='input'
        tooltip
      /> */}
      {/* <Graph 
        title='imbalance from 1 step'
        data={data1} 
        lineDataKey="imbalance"
        xAxisDataKey='input'
        tooltip
      /> */}
      <Graph
        title='revenue from iterator' 
        data={data2}
        lineDataKey="diff"
        xAxisDataKey='input'
        verticalX={inputFromIterator.toFixed(0)}
        tooltip
      />
      {/* <Graph 
        title='imbalance from iterator'
        data={data2} 
        lineDataKey="imbalance"
        xAxisDataKey='input'
        tooltip
      /> */}
    </Fragment>
  )
}

export default TriGraphs