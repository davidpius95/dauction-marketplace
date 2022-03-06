const { parseEther, formatEther } = require('@ethersproject/units')

const parseToken = payload => parseEther(payload.toString()) 

const formatToken = payload => formatEther(payload.toString())

module.exports = {parseToken, formatToken}