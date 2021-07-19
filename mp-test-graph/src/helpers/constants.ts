import BigNumber from "bignumber.js";
import { sumOf } from "./helpers";

export const SWAP_FEE_TARGET = new BigNumber(.997)
export const ONE = new BigNumber(1)
export const SWAP_FEE_ACTUAL1 = new BigNumber(.997)
export const SWAP_FEE_ACTUAL2 = new BigNumber(.997)
export const SWAP_FEE_ACTUAL3 = new BigNumber(.997)
export const SWAP_FEE_ACTUAL4 = new BigNumber(.997)
export const SWAP_FEE_SIMPLE_SUM = sumOf(ONE.minus(SWAP_FEE_ACTUAL1), ONE.minus(SWAP_FEE_ACTUAL2))
export const SWAP_FEE_TRI_SUM = sumOf(ONE.minus(SWAP_FEE_ACTUAL1), ONE.minus(SWAP_FEE_ACTUAL2), ONE.minus(SWAP_FEE_ACTUAL3))
export const SWAP_FEE_QUAD_SUM = sumOf(ONE.minus(SWAP_FEE_ACTUAL1), ONE.minus(SWAP_FEE_ACTUAL2), ONE.minus(SWAP_FEE_ACTUAL3), ONE.minus(SWAP_FEE_ACTUAL4))
export const NUM_DECIMALS = 6

export const TRI_GRAPHS = false
export const QUAD_GRAPHS = true
