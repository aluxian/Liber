const util = require('util');
const authy = require('authy');
const request = require('request');

const AUTHY_API_KEY = 'KiPj41iB83L66Q90y9CQh8feaB3pxBkx';

// The Cloud Functions for Firebase SDK to create Cloud Functions and setup triggers.
const functions = require('firebase-functions');

// The Firebase Admin SDK to access the Firebase Realtime Database.
const admin = require('firebase-admin');
admin.initializeApp();

// Create and Deploy Your First Cloud Functions
// https://firebase.google.com/docs/functions/write-firebase-functions

exports.sendMobileCode = functions.https.onCall((data, context) => {
	const client = authy(AUTHY_API_KEY);
	client.verifyAsync = util.promisify(client.phones().verification_start);
	return client.verifyAsync(data.phoneNumber, data.countryCode, { via: 'sms', code_length: 4 });
});

exports.finishSignUp = functions.https.onCall((data, context) => {
	var enduser_id;
    //create RB account and store enduser_id to FireBase
    request.post({url:'https://play.railsbank.com/v1/customer/endusers', formData: {
        person: {
            name: data.name,
            telephone: data.phoneNumber
        }
    }}, function (error, response, body) {
        if (err) {
            return console.error('failed:', err);
        }
        
        enduser_id = body;
    });
    
    console.log(enduser_id);
});