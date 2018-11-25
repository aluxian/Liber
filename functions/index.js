const util = require('util');
const authy = require('authy');
const request = require('request-promise-native');

// play key:
// l0mvqwv9zvpg4s8aup5376475b6wtg0i#x0xhdvqsdahmoczcdu8g1k2dsrhl7gcdu107962gookg31uddosslqa2v3oe8f14

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
		url: 'https://playlive.railsbank.com/v1/customer/endusers/' + enduser_id + '/wait',
		headers: {
			Authorization:
				'API-Key axkqhp9y1iw1vtgm56c4cnf77i9npjca#xtz4si9frce3kbx80ivnyi32thhblx1slcwipw0qv50dhrq2crdhvpy1ueyvkv5f',
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
		url: 'https://playlive.railsbank.com/v1/customer/ledgers/' + ledger_id + '/wait',
		headers: {
			Authorization:
				'API-Key axkqhp9y1iw1vtgm56c4cnf77i9npjca#xtz4si9frce3kbx80ivnyi32thhblx1slcwipw0qv50dhrq2crdhvpy1ueyvkv5f',
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

async function refreshTransactions(phoneNumber, ledger_id) {
	let response = await request.get({
		url: 'https://playlive.railsbank.com/v1/customer/transactions',
		headers: {
			Authorization:
				'API-Key axkqhp9y1iw1vtgm56c4cnf77i9npjca#xtz4si9frce3kbx80ivnyi32thhblx1slcwipw0qv50dhrq2crdhvpy1ueyvkv5f',
		},
		json: true,
		resolveWithFullResponse: true,
	});

	console.log('rasp status code=', response.statusCode || response.status);
	console.log(response.body);

	const extractedResponse = [];

	for (let i = 0; i < response.body.length; i++) {
		if (response.body[i].ledger_from_id === ledger_id || response.body[i].ledger_to_id === ledger_id) {
			extractedResponse.push(response.body[i]);
		}
	}

	await db
		.ref('users')
		.child(phoneNumber)
		.child('transactions')
		.set(extractedResponse);

	console.log('refreshtransactions success');
}

function createEnduser(data) {
	return request.post({
		url: 'https://playlive.railsbank.com/v1/customer/endusers',
		body: {
			person: {
				name: data.name,
				telephone: data.phoneNumber,
			},
		},
		headers: {
			Authorization:
				'API-Key axkqhp9y1iw1vtgm56c4cnf77i9npjca#xtz4si9frce3kbx80ivnyi32thhblx1slcwipw0qv50dhrq2crdhvpy1ueyvkv5f',
		},
		json: true,
		resolveWithFullResponse: true,
	});
}

function createLedger(data, enduser_id) {
	return request.post({
		url: 'https://playlive.railsbank.com/v1/customer/ledgers',
		body: {
			asset_class: 'currency',
			asset_type: 'gbp',
			holder_id: enduser_id,
			ledger_primary_use_types: ['ledger-primary-use-types-investment'],
			ledger_t_and_cs_country_of_jurisdiction: 'GBR',
			ledger_type: 'ledger-type-single-user',
			ledger_who_owns_assets: 'ledger-assets-owned-by-me',
			partner_product: 'PayrNet-GBP-1',
		},
		headers: {
			Authorization:
				'API-Key axkqhp9y1iw1vtgm56c4cnf77i9npjca#xtz4si9frce3kbx80ivnyi32thhblx1slcwipw0qv50dhrq2crdhvpy1ueyvkv5f',
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

		await db
			.ref('users')
			.child(data.phoneNumber)
			.child('allocation') // ticker -> pct
			.set({
				'CASH.GBP': 100,
			});

		await db
			.ref('users')
			.child(data.phoneNumber)
			.child('amounts') // ticker -> amount
			.set({
				'CASH.GBP': 0.0,
			});

		return 'nicky';
	};

	return exec();
});

async function refreshPayment(amount, ledger_id, beneficiary_id, phoneNumber) {
	let response = await request.post({
		url: 'https://playlive.railsbank.com/v1/customer/transactions',
		body: {
			amount: amount,
			beneficiary_id: beneficiary_id,
			ledger_from_id: ledger_id,
			payment_type: 'payment-type-UK-FasterPayments',
		},
		headers: {
			Authorization:
				'API-Key axkqhp9y1iw1vtgm56c4cnf77i9npjca#xtz4si9frce3kbx80ivnyi32thhblx1slcwipw0qv50dhrq2crdhvpy1ueyvkv5f',
		},
		json: true,
		resolveWithFullResponse: true,
	});

	console.log('rasp status code=', response.statusCode || response.status);
	console.log(response.body);

	response = await request.get({
		url: 'https://playlive.railsbank.com/v1/customer/transactions/' + response.body.transaction_id,
		headers: {
			Authorization:
				'API-Key axkqhp9y1iw1vtgm56c4cnf77i9npjca#xtz4si9frce3kbx80ivnyi32thhblx1slcwipw0qv50dhrq2crdhvpy1ueyvkv5f',
		},
		json: true,
		resolveWithFullResponse: true,
	});

	console.log('rasp status code=', response.statusCode || response.status);
	console.log(response.body);

	await refreshLedger(phoneNumber, ledger_id);
	await refreshTransactions(phoneNumber, ledger_id);

	console.log('refreshpayment success');
}

function createBeneficiary(data, enduser_id) {
	return request.post({
		url: 'https://playlive.railsbank.com/v1/customer/beneficiaries',
		body: {
			asset_class: 'currency',
			asset_type: 'gbp',
			holder_id: enduser_id,
			person: {
				name: data.name,
			},
			uk_account_number: data.accno,
			uk_sort_code: data.sortcode,
		},
		headers: {
			Authorization:
				'API-Key axkqhp9y1iw1vtgm56c4cnf77i9npjca#xtz4si9frce3kbx80ivnyi32thhblx1slcwipw0qv50dhrq2crdhvpy1ueyvkv5f',
		},
		json: true,
		resolveWithFullResponse: true,
	});
}

exports.withdraw = functions.https.onCall((data, context) => {
	const exec = async function() {
		const snapshot = await db
			.ref('users')
			.child(data.phoneNumber)
			.once('value');

		const beneficiaryResponse = await createBeneficiary(data, snapshot.val().enduser_id);
		console.log('rasp status code=', beneficiaryResponse.statusCode || beneficiaryResponse.status);
		console.log(beneficiaryResponse.body);

		const beneficiary_id = beneficiaryResponse.body.beneficiary_id;

		await refreshPayment(data.amount, snapshot.val().ledger_id, beneficiary_id, data.phoneNumber);

		return 'alex';
	};

	return exec();
});

exports.importAprexo = functions.https.onRequest((req, res) => {
	const exec = async function() {
		const response = await request.get({
			url: 'https://aprexocoreapiuk3.azurewebsites.net/api/v1/Instrument',
			headers: {
				Authorization:
					'Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6IndVTG1ZZnNxZFF1V3RWXy1oeFZ0REpKWk00USIsImtpZCI6IndVTG1ZZnNxZFF1V3RWXy1oeFZ0REpKWk00USJ9.eyJhdWQiOiI2ZThlZjRlNS1iY2JjLTRlYzYtODU3Ni1lMGQ1MzkwYjRkOGUiLCJpc3MiOiJodHRwczovL3N0cy53aW5kb3dzLm5ldC9kYmMwYjNkNy0yY2QwLTQwMDUtYTY5YS03OGJhZTA1MzA5NzgvIiwiaWF0IjoxNTQzMTIzMzg5LCJuYmYiOjE1NDMxMjMzODksImV4cCI6MTU0MzEyNzI4OSwiYWNyIjoiMSIsImFpbyI6IkFTUUEyLzhKQUFBQXJTdkxySnJSRi9QbkdudFVaT1hUaXc4WkhJR3VtOVlycDAzQ3RDM3A4N2s9IiwiYW1yIjpbInB3ZCJdLCJhcHBpZCI6IjcxZDZlMWNjLTVkYWItNDY2Yi05NDE0LTdiZjg4NWQ5YmFjNiIsImFwcGlkYWNyIjoiMCIsImZhbWlseV9uYW1lIjoiaGFja2F0aG9uMjAxOCIsImlwYWRkciI6IjE5My42MC43OS4xNzAiLCJuYW1lIjoiaGFja2F0aG9uMjAxOCIsIm9pZCI6ImE3YWExNzNlLTM3ZjktNGRkMS04MDAzLTM0ZmNhMDMyOThlMiIsInNjcCI6InVzZXJfaW1wZXJzb25hdGlvbiIsInN1YiI6InlFU2d0Vl83WWFUaVdMZVA5QzhmZEJhVU9CNzhkQTdCZnZZOUhLZzE1YWciLCJ0aWQiOiJkYmMwYjNkNy0yY2QwLTQwMDUtYTY5YS03OGJhZTA1MzA5NzgiLCJ1bmlxdWVfbmFtZSI6ImhhY2thdGhvbjIwMThAYXByZXhvLmNvbSIsInVwbiI6ImhhY2thdGhvbjIwMThAYXByZXhvLmNvbSIsInV0aSI6ImZzSmd4ZDNiS0VDMEFGY2xkVGItQUEiLCJ2ZXIiOiIxLjAifQ.D_cbDVlceMCn_Ie8qWhT-F2_PnbJy8tGrn-KgCh_iojXaN7VLlS7tbLzfZXFCoDxp3GkRwmH7WurCpJHcsqhdHZUSn7Hnik1fAbH98FIFuDt0KFQpULUg7HSS1XGqH_rObbnTAsWgy8KqkeD9kqy4CzSDyOoll-ZfyOTKZANqlVncy2yj5MzrCmcmSmT5VgnUUcj2RJuh9CerUNUSskRNd-DOjVUjZMbGrAEOVzwT6iSXt7Z0Ou4rb1wLSIztFAgyTVMP2K5lLQnhMfcpkFO-eNt4a6-J3Pzz-y4FB3EK6PEs_8U5O02GaSA8Ip92fPozaK9QEDc5U0p5bdTrlLsFQ',
			},
			json: true,
			resolveWithFullResponse: true,
		});

		console.log('rasp status code=', response.statusCode || response.status);
		console.log(response.body);

		let instruments = [];

		for (let i = 0; i < response.body.length; i++) {
			let inst = null;

			if (response.body[i].id === 'CASH.GBP') {
				inst = {
					ticker: response.body[i].id.replace('.', '_'),
					sym: response.body[i].id.split('.')[1],
					cls: response.body[i].id.split('.')[0],
					name: response.body[i].name,
					risk: 0,
				};
				instruments.push(inst);
				continue;
			}
			let type = response.body[i].id.split('.')[0];
			if (type === 'CRYPT') {
				inst = {
					ticker: response.body[i].id.replace('.', '_'),
					sym: response.body[i].id.split('.')[1],
					cls: response.body[i].id.split('.')[0],
					name: response.body[i].name,
					risk: 8,
				};
			} else if (type === 'COM') {
				inst = {
					ticker: response.body[i].id.replace('.', '_'),
					sym: response.body[i].id.split('.')[1],
					cls: response.body[i].id.split('.')[0],
					name: response.body[i].name,
					risk: 3,
				};
			} else if (type === 'CASH') {
				inst = {
					ticker: response.body[i].id.replace('.', '_'),
					sym: response.body[i].id.split('.')[1],
					cls: response.body[i].id.split('.')[0],
					name: response.body[i].name,
					risk: 1,
				};
			} else if (type === 'BOND') {
				inst = {
					ticker: response.body[i].id.replace('.', '_'),
					sym: response.body[i].id.split('.')[1],
					cls: response.body[i].id.split('.')[0],
					name: response.body[i].name,
					risk: 2,
				};
			} else if (type === 'FX') {
				inst = {
					ticker: response.body[i].id.replace('.', '_'),
					sym: response.body[i].id.split('.')[1],
					cls: response.body[i].id.split('.')[0],
					name: response.body[i].name,
					risk: 2,
				};
			} else if (type === 'EQUITY') {
				inst = {
					ticker: response.body[i].id.replace('.', '_'),
					sym: response.body[i].id.split('.')[1],
					cls: response.body[i].id.split('.')[0],
					name: response.body[i].name,
					risk: 5,
				};
			}

			if (inst) {
				instruments.push(inst);
			}
		}

		await db.ref('instruments').set(instruments);

		return 'alex';
	};

	exec()
		.then(() => res.send('ok'))
		.catch((err) => {
			console.log(err);
			res.send('error');
		});
});

async function getBtcPrice() {
	const response = await request.get({
		url: 'https://api.coindesk.com/v1/bpi/currentprice.json',
		json: true,
		resolveWithFullResponse: true,
	});

	// console.log('rasp status code=', response.statusCode || response.status);
	// console.log(response.body);

	//find the bitcoin key and then change the value
	// console.log(response.body.bpi.GBP);
	return parseFloat(response.body.bpi.GBP.rate.replace(',', ''));
}

exports.continuouslyUpdateBtcAmount = functions.https.onRequest((req, res) => {
	const exec = async function() {
		while (1) {
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
		}

		return 'alex';
	};

	exec()
		.then(() => res.send('ok'))
		.catch((err) => {
			console.log(err);
			res.send('error');
		});
});

exports.liveBitcoin = functions.https.onRequest((req, res) => {
	const exec = async function() {
		const response = await request.get({
			url: 'https://api.coindesk.com/v1/bpi/currentprice.json',
			json: true,
			resolveWithFullResponse: true,
		});

		console.log('rasp status code=', response.statusCode || response.status);
		console.log(response.body);

		//find the bitcoin key and then change the value

		await db
			.ref('instruments')
			.child('19')
			.child('value')
			.set(parseFloat(response.body.GBP.rate));

		return 'alex';
	};

	exec()
		.then(() => res.send('ok'))
		.catch((err) => {
			console.log(err);
			res.send('error');
		});
});

exports.railsbankWebhook = functions.https.onRequest((req, res) => {
	console.log(req.body);
	// import all ledger txs into firebase again

	if (req.body.type !== 'ledger-changed') {
		console.log('ignored');
		return res.send('whatever');
	}

	const exec = async function() {
		const allUsers = (await db.ref('users').once('value')).val();
		let phoneNumber = null;

		for (let i_phoneNumber of Object.keys(allUsers)) {
			if (allUsers[i_phoneNumber].ledger_id === req.body.ledger_id) {
				phoneNumber = i_phoneNumber;
				break;
			}
		}

		if (phoneNumber) {
			await Promise.all([
				refreshLedger(phoneNumber, req.body.ledger_id),
				refreshTransactions(phoneNumber, req.body.ledger_id),
			]);
		} else {
			console.warn('phone number is null ');
		}

		if (req.body.transaction_id) {
			const tx_response = await request.get({
				url: 'https://playlive.railsbank.com/v1/customer/transactions/' + req.body.transaction_id,
				headers: {
					Authorization:
						'API-Key axkqhp9y1iw1vtgm56c4cnf77i9npjca#xtz4si9frce3kbx80ivnyi32thhblx1slcwipw0qv50dhrq2crdhvpy1ueyvkv5f',
				},
				json: true,
				resolveWithFullResponse: true,
			});
			const tx = tx_response.body;

			if (tx.transaction_type === 'transaction-type-send') {
				// withdraw amounts
				const allocation = (await db
					.ref('users')
					.child(data.phoneNumber)
					.child('allocation')
					.once('value')).val();

				await Promise.all(
					Object.keys(allocation).map(async function(alloc_ticker) {
						const pct = allocation[alloc_ticker];
						const alloc_to_this_ticker = (tx.amount * pct) / 100;

						return await db
							.ref('users')
							.child(data.phoneNumber)
							.child('amounts')
							.child(alloc_ticker)
							.transaction(function(am) {
								return am ? am - alloc_to_this_ticker : 0;
							});
					}),
				);
			}

			if (tx.transaction_type === 'transaction-type-receive') {
				// credit amounts
				const allocation = (await db
					.ref('users')
					.child(data.phoneNumber)
					.child('allocation')
					.once('value')).val();

				await Promise.all(
					Object.keys(allocation).map(async function(alloc_ticker) {
						const pct = allocation[alloc_ticker];
						const alloc_to_this_ticker = (tx.amount * pct) / 100;

						return await db
							.ref('users')
							.child(data.phoneNumber)
							.child('amounts')
							.child(alloc_ticker)
							.transaction(function(am) {
								return am ? am + alloc_to_this_ticker : alloc_to_this_ticker;
							});
					}),
				);
			}
		}
	};

	exec()
		.then(() => res.send('ok'))
		.catch((err) => {
			console.error(err);
			res.send(err || 'err');
		});
});
