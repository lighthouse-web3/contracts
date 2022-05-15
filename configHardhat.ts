export interface networkConfigItem {
    ethUsdPriceFeed?: string
    blockConfirmations?: number
  }
  
  export interface networkConfigInfo {
    [key: string]: networkConfigItem
  }

  export const developmentChains = ["hardhat", "localhost"]
  
  // Governor Values
  export const QUORUM_PERCENTAGE = 51 // Need 51% of voters to pass
  export const MIN_DELAY = 3600 // 1 hour - after a vote passes, you have 1 hour before you can enact
  // export const VOTING_PERIOD = 45818 // 1 week - how long the vote lasts. This is pretty long even for local tests
  export const VOTING_PERIOD = 5 // blocks
  export const VOTING_DELAY = 1 // 1 Block - How many blocks till a proposal vote becomes active
  export const ADDRESS_ZERO = "0x0000000000000000000000000000000000000000"
  export const polygonProvider = "0x5343b5bA672Ae99d627A1C87866b8E53F47Db2E6"
  