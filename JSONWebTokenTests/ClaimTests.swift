//
//  ClaimTests.swift
//  JSONWebToken
//
//  Created by Antoine Palazzolo on 24/11/15.
//

import Foundation

import JSONWebToken
import XCTest

class ClaimTests : XCTestCase {

    func testValidateAllClaims() {
        let jwts = ["all_claim_valid_1","all_claim_valid_2"].map(ReadSampleWithName)
        let validatorBase = IssuerValidator & SubjectValidator & JWTIdentifierValidator & AudienceValidator & ExpirationTimeValidator & NotBeforeValidator & IssuedAtValidator
        
        jwts.forEach {
            let validation = validatorBase.validateToken($0)
            XCTAssertTrue(validation.isValid, "\(validation)")
        }
        
        let validatorValues = IssuerValidator.withValidator {$0 == "kreactive"} &
            SubjectValidator.withValidator {$0 == "antoine"} &
            JWTIdentifierValidator.withValidator{$0 == "123456789"} &
            AudienceValidator.withValidator {$0.contains("test-app")}
        
        jwts.forEach {
            let validation = validatorValues.validateToken($0)
            XCTAssertTrue(validation.isValid, "\(validation)")
        }
    }
    func testValidateAllClaimsSigned() {
        let validator = IssuerValidator.withValidator {$0 == "kreactive"} &
            SubjectValidator.withValidator {$0 == "antoine"} &
            JWTIdentifierValidator.withValidator{$0 == "123456789"} &
            AudienceValidator.withValidator {$0.contains("test-app")} &
            HMACSignature(secret: "secret".dataUsingEncoding(NSUTF8StringEncoding)!, hashFunction: .SHA256)
        
        let jwt = ReadSampleWithName("all_claim_valid_2_signed")
        let validation = validator.validateToken(jwt)
        XCTAssertTrue(validation.isValid, "\(validation)")
    }
    
    func testValidateClaimsGetter() {
        let jwts = ["all_claim_valid_1","all_claim_valid_2"].map(ReadSampleWithName)
        jwts.forEach {
            XCTAssertTrue($0.payload.audience.contains("test-app"))
            XCTAssertTrue($0.payload.issuer! == "kreactive")
            XCTAssertTrue($0.payload.subject! == "antoine")
            XCTAssertTrue($0.payload.jwtIdentifier! == "123456789")
            XCTAssertTrue($0.payload.expiration!.timeIntervalSinceNow >= 0)
            XCTAssertTrue($0.payload.notBefore!.timeIntervalSinceNow <= 0)
            XCTAssertTrue($0.payload.issuedAt != nil)
        }
    }
    func testValidateClaimsEmpty() {
        let tokens = ["empty","empty2"].map(ReadSampleWithName)
        tokens.forEach { jwt in
            XCTAssertTrue(jwt.payload.audience == [])
            XCTAssertNil(jwt.payload.issuer)
            XCTAssertNil(jwt.payload.subject)
            XCTAssertNil(jwt.payload.jwtIdentifier)
            XCTAssertNil(jwt.payload.expiration)
            XCTAssertNil(jwt.payload.notBefore)
            XCTAssertNil(jwt.payload.issuedAt)
            
            let validator = IssuerValidator & SubjectValidator & JWTIdentifierValidator & AudienceValidator & ExpirationTimeValidator & NotBeforeValidator & IssuedAtValidator
            let validation = validator.validateToken(jwt)
            XCTAssertFalse(validation.isValid)
            
            let validatorOptional = IssuerValidator.optionalValidator & SubjectValidator.optionalValidator & JWTIdentifierValidator.optionalValidator & AudienceValidator.optionalValidator & ExpirationTimeValidator.optionalValidator & NotBeforeValidator.optionalValidator & IssuedAtValidator.optionalValidator
            let validationOpt = validatorOptional.validateToken(jwt)
            XCTAssertTrue(validationOpt.isValid)
        }

    }
    func testOrCombine() {
        let jwt = ReadSampleWithName("RS512")
        let verifier = RSAPKCS1Verifier(hashFunction: .SHA512, key : SamplePublicKey)
        let otherVerifier = HMACSignature(secret: "secret".dataUsingEncoding(NSUTF8StringEncoding)!, hashFunction: .SHA512)
        XCTAssertTrue((verifier|otherVerifier).validateToken(jwt).isValid)
        XCTAssertTrue((otherVerifier|verifier).validateToken(jwt).isValid)

    }
    func testInvalidAudience() {
        let invalidFormat = ReadSampleWithName("invalid_aud_format")
        XCTAssertTrue(invalidFormat.payload.audience == [])
        let validationFormat = AudienceValidator.optionalValidator.validateToken(invalidFormat)
        XCTAssertFalse(validationFormat.isValid)
        
    }
    func testInvalidExp() {
        let invalidFormat = ReadSampleWithName("invalid_exp_format")
        XCTAssertNil(invalidFormat.payload.expiration)
        let validationFormat = ExpirationTimeValidator.optionalValidator.validateToken(invalidFormat)
        XCTAssertFalse(validationFormat.isValid)
        
        let expired = ReadSampleWithName("invalid_expired")
        XCTAssertNotNil(expired.payload.expiration)
        let validationExpired = ExpirationTimeValidator.optionalValidator.validateToken(expired)
        XCTAssertFalse(validationExpired.isValid)
    }
    func testInvalidIat() {
        let invalidFormat = ReadSampleWithName("invalid_iat_format")
        XCTAssertNil(invalidFormat.payload.issuedAt)
        let validationFormat = IssuedAtValidator.optionalValidator.validateToken(invalidFormat)
        XCTAssertFalse(validationFormat.isValid)
    }
    func testInvalidIss() {
        let invalidFormat = ReadSampleWithName("invalid_iss_format")
        XCTAssertNil(invalidFormat.payload.issuer)
        let validationFormat = IssuerValidator.optionalValidator.validateToken(invalidFormat)
        XCTAssertFalse(validationFormat.isValid)
    }
    func testInvalidJWTIdentifier() {
        let invalidFormat = ReadSampleWithName("invalid_jti_format")
        XCTAssertNil(invalidFormat.payload.jwtIdentifier)
        let validationFormat = JWTIdentifierValidator.optionalValidator.validateToken(invalidFormat)
        XCTAssertFalse(validationFormat.isValid)
    }
    func testInvalidNbf() {
        let invalidFormat = ReadSampleWithName("invalid_nbf_format")
        XCTAssertNil(invalidFormat.payload.notBefore)
        let validationFormat = NotBeforeValidator.optionalValidator.validateToken(invalidFormat)
        XCTAssertFalse(validationFormat.isValid)
        
        let expired = ReadSampleWithName("invalid_nbf_immature")
        XCTAssertNotNil(expired.payload.notBefore)
        let validationExpired = NotBeforeValidator.optionalValidator.validateToken(expired)
        XCTAssertFalse(validationExpired.isValid)
    }
    func testInvalidSub() {
        let invalidFormat = ReadSampleWithName("invalid_sub_format")
        XCTAssertNil(invalidFormat.payload.subject)
        let validationFormat = SubjectValidator.optionalValidator.validateToken(invalidFormat)
        XCTAssertFalse(validationFormat.isValid)
        
    }
}
