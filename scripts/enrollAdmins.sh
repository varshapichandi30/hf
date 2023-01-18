fabric-ca-client enroll -d -u http://admin:admin-pw@localhost:7054

fabric-ca-client register --id.name ord-admin --id.secret OrdAdm1nPW --id.attrs 'admin=true:ecert'
FABRIC_CA_CLIENT_HOME=./config fabric-ca-client enroll -u http://ord-admin:OrdAdm1nPW@localhost:7054 -M ./OrdererMSP
mkdir -p ./config/OrdererMSP/admincerts
cp ./config/OrdererMSP/signcerts/* ./config/OrdererMSP/admincerts

fabric-ca-client register --id.name peer-admin --id.secret PeerAdm1nPW --id.attrs 'admin=true:ecert'
FABRIC_CA_CLIENT_HOME=./config fabric-ca-client enroll -u http://peer-admin:PeerAdm1nPW@localhost:7054 -M ./PeerMSP
mkdir -p ./config/PeerMSP/admincerts
cp ./config/PeerMSP/signcerts/* ./config/PeerMSP/admincerts