const util = require('util');
const authy = require('authy');
const request = require('request-promise-native');

const AUTHY_API_KEY = 'KiPj41iB83L66Q90y9CQh8feaB3pxBkx';

// The Cloud Functions for Firebase SDK to create Cloud Functions and setup triggers.
const functions = require('firebase-functions');

// The Firebase Admin SDK to access the Firebase Realtime Database.
const admin = require('firebase-admin');
admin.initializeApp();

// Get a database reference to our blog
var db = admin.database();

// Create and Deploy Your First Cloud Functions
// https://firebase.google.com/docs/functions/write-firebase-functions

exports.sendMobileCode = functions.https.onCall((data, context) => {
	const client = authy(AUTHY_API_KEY);
	client.verifyAsync = util.promisify(client.phones().verification_start);
	return client.verifyAsync(data.phoneNumber, data.countryCode, { via: 'sms', code_length: 4 });
});

async function refreshEnduser(phoneNumber, enduser_id) {
	await db
		.ref('users')
		.child(phoneNumber)
		.child('enduser_id')
		.set(enduser_id);

	let response = await request.get({
		url: 'https://play.railsbank.com/v1/customer/endusers/' + enduser_id,
		headers: {
			Authorization:
				'API-Key l0mvqwv9zvpg4s8aup5376475b6wtg0i#x0xhdvqsdahmoczcdu8g1k2dsrhl7gcdu107962gookg31uddosslqa2v3oe8f14',
		},
		json: true,
		resolveWithFullResponse: true,
	});

	console.log('rasp status code=', response.statusCode || response.status);
	console.log(response.body);

	await db
		.ref('users')
		.child(phoneNumber)
		.child('enduser')
		.set(response.body);

	console.log('refreshEnduser success');
}

async function refreshLedger(phoneNumber, ledger_id) {
	await db
		.ref('users')
		.child(phoneNumber)
		.child('ledger_id')
		.set(ledger_id);

	let response = await request.get({
		url: 'https://play.railsbank.com/v1/customer/ledgers/' + ledger_id,
		headers: {
			Authorization:
				'API-Key l0mvqwv9zvpg4s8aup5376475b6wtg0i#x0xhdvqsdahmoczcdu8g1k2dsrhl7gcdu107962gookg31uddosslqa2v3oe8f14',
		},
		json: true,
		resolveWithFullResponse: true,
	});

	console.log('rasp status code=', response.statusCode || response.status);
	console.log(response.body);

	await db
		.ref('users')
		.child(phoneNumber)
		.child('ledger')
		.set(response.body);

	console.log('refreshledger success');
}

function createEnduser(data) {
	return request.post({
		url: 'https://play.railsbank.com/v1/customer/endusers',
		body: {
			person: {
				name: data.name,
				telephone: data.phoneNumber,
			},
		},
		headers: {
			Authorization:
				'API-Key l0mvqwv9zvpg4s8aup5376475b6wtg0i#x0xhdvqsdahmoczcdu8g1k2dsrhl7gcdu107962gookg31uddosslqa2v3oe8f14',
		},
		json: true,
		resolveWithFullResponse: true,
	});
}

function createLedger(data, enduser_id) {
	return request.post({
		url: 'https://play.railsbank.com/v1/customer/ledgers',
		body: {
			asset_class: 'currency',
			asset_type: 'gbp',
			holder_id: enduser_id,
			ledger_primary_use_types: ['ledger-primary-use-types-investment'],
			ledger_t_and_cs_country_of_jurisdiction: 'GBR',
			ledger_type: 'ledger-type-single-user',
			ledger_who_owns_assets: 'ledger-assets-owned-by-me',
			partner_product: 'ExampleBank-GBP-1',
		},
		headers: {
			Authorization:
				'API-Key l0mvqwv9zvpg4s8aup5376475b6wtg0i#x0xhdvqsdahmoczcdu8g1k2dsrhl7gcdu107962gookg31uddosslqa2v3oe8f14',
		},
		json: true,
		resolveWithFullResponse: true,
	});
}

exports.finishSignUp = functions.https.onCall((data, context) => {
	//var enduser_id;
	//create RB account and store enduser_id to FireBase

	const exec = async function() {
		let enduserResponse = await createEnduser(data);
		console.log('rasp status code=', enduserResponse.statusCode || enduserResponse.status);
		console.log(enduserResponse.body);
		await refreshEnduser(data.phoneNumber, enduserResponse.body.enduser_id);

		let ledgerResponse = await createLedger(data, enduserResponse.body.enduser_id);
		console.log('rasp status code=', ledgerResponse.statusCode || ledgerResponse.status);
		console.log(ledgerResponse.body);
		await refreshLedger(data.phoneNumber, ledgerResponse.body.ledger_id);
		await refreshTransactions(ledgerResponse.body.ledger_id);

		return 'nicky';
	};

	return exec();
});

exports.railsbankWebhook = functions.https.onRequest((req, res) => {
	req.query.name;
	console.log(req.body);
	// should have ledger id and tx id
	// import all ledger txs into firebase again
	return 'ok';
});
