export NUM=1
fabric-ca-client register --id.name ord${NUM} --id.secret ord${NUM}_pw --id.type orderer
FABRIC_CA_CLIENT_HOME=./config fabric-ca-client enroll -d -u http://ord${NUM}:ord${NUM}_pw@$localhost:7054 -M ord${NUM}_MSP/msp


# generate tls certificates
FABRIC_CA_CLIENT_HOME=./config fabric-ca-client enroll -u http://ord${NUM}:ord${NUM}_pw@$localhost:7054 -M ord${NUM}_MSP/tls --enrollment.profile tls --csr.hosts ord1-hlf-ord.orderers.svc.cluster.local

# create tls certificates for orderer node
cp ./config/ord${NUM}_MSP/tls/tlscacerts/* ./config/ord${NUM}_MSP/tls/ca.crt
cp ./config/ord${NUM}_MSP/tls/signcerts/* ./config/ord${NUM}_MSP/tls/server.crt
cp ./config/ord${NUM}_MSP/tls/keystore/* ./config/ord${NUM}_MSP/tls/server.key

# create tls certificates for orderer org
mkdir -p ./config/OrdererMSP/tlscacerts
cp ./config/ord${NUM}_MSP/tls/tlscacerts/* ./config/OrdererMSP/tlscacerts/tlsca.orderers.svc.cluster.local-cert.pem
