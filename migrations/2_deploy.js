const AgoClaimer = artifacts.require('AgoClaimer')
const TheAgo = artifacts.require('TheAgo')

module.exports = async function (deployer, network) {
  return deployer.then(function () {
    return AgoClaimer.new()
  }).then(function (instance) {
    console.log('AgoClaimer : ', instance.address)
    return TheAgo.new(instance.address);
  }).then(function (instance) {
    console.log('TheAgo : ', instance.address)
  })
}
