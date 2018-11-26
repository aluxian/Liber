const util = require('util');
const request = require('request-promise-native');

// The Firebase Admin SDK to access the Firebase Realtime Database.
const admin = require('firebase');
console.log('preinit');
var config = {
	apiKey: 'AIzaSyAGoh6F8G1DgeG16JplUnBhCb0LMuclH4A',
	authDomain: 'liber-98ff3.firebaseapp.com',
	databaseURL: 'https://liber-98ff3.firebaseio.com',
	projectId: 'liber-98ff3',
	storageBucket: 'liber-98ff3.appspot.com',
	messagingSenderId: '1094026479299',
};
admin.initializeApp(config);
console.log('done init');

// Get a database reference to our blog
var db = admin.database();

// Create and Deploy Your First Cloud Functions
// https://firebase.google.com/docs/functions/write-firebase-functions

async function getBtcPrice() {
	console.log('getbtcprice');
	const response = await request.get({
		url: 'https://api.coindesk.com/v1/bpi/currentprice.json',
		json: true,
		resolveWithFullResponse: true,
	});

	console.log('rasp status code=', response.statusCode || response.status);
	console.log(response.body);

	// find the bitcoin key and then change the value
	console.log(response.body.bpi.GBP);
	return parseFloat(response.body.bpi.GBP.rate.replace(',', ''));
}

async function sync() {
	await new Promise(function(resolve) {
		setTimeout(resolve, 3000);
	});

	let s = await db
		.ref('users')
		.child(req.query.phoneNumber)
		.child('amounts')
		.child('CRYPT_BTC')
		.once('value');

	const prev_amount_btc = s.val();

	s = await db
		.ref('instruments')
		.child('19')
		.child('value')
		.once('value');

	const prev_rate_btc = s.val();

	const new_price = await getBtcPrice();

	const new_amount = (prev_amount_btc * new_price) / prev_rate_btc;

	await db
		.ref('users')
		.child(req.query.phoneNumber)
		.child('amounts')
		.child('CRYPT_BTC')
		.set(new_amount);

	await db
		.ref('instruments')
		.child('19')
		.child('value')
		.set(new_price);

	s = await db
		.ref('users')
		.child(req.query.phoneNumber)
		.child('amounts')
		.once('value');
	const all_amounts = s.val();
	const total_value = Object.values(all_amounts).reduce(function(acc, nv) {
		return acc + nv;
	}, 0);

	await db
		.ref('users')
		.child(req.query.phoneNumber)
		.child('valuation_chart')
		.push()
		.set({
			timestamp: Date.now(),
			value: total_value,
		});

	await sync();
}

console.log('a');

sync()
	.then()
	.catch((err) => console.log(err));

console.log('b');
