configtxgen -profile OrdererGenesis -outputBlock ./genesis.block -channelID system-channel
configtxgen -profile MyChannel -channelID mychannel -outputCreateChannelTx ./mychannel.tx

kubectl create secret generic -n orderers hlf--genesis --from-file=genesis.block
kubectl create secret generic -n peers hlf--channel --from-file=mychannel.tx