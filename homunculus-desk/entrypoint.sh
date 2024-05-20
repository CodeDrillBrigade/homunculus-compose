rm -rf Homunculus-desk
rm -rf /homunculus
mkdir /homunculus
npm install -g yarn
git clone https://github.com/CodeDrillBrigade/Homunculus-desk.git --depth=1
cp .env /Homunculus-desk
cd Homunculus-desk
yarn install
yarn build
mv ./build/* ../homunculus
nginx -g 'daemon off;'
