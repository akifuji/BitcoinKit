//
//  BitcoinKitTests.swift
//  BitcoinKitTests
//
//  Created by Akifumi Fujita on 2019/01/06.
//  Copyright © 2019 BitcoinKit developers. All rights reserved.
//

import XCTest
@testable import BitcoinKit

class MessageTests: XCTestCase {
    
    func testWIF() {
        let data = Data(hex: "0b110907686561646572730000000000d3780200320f23dafdd0070100000043497fd7f826957108f4a30fd9cec3aeba79972084e90ead01ea330900000000bac8b0fa927c0ac8234287e33c5f74d38d354820e24756ad709d7038fc5f31f020e7494dffff001d03e4b672000100000006128e87be8b1b4dea47a7247d5528d2702c96826c7a648497e773b800000000e241352e3bec0a95a6217e10c3abb54adfa05a")
        let m = MessageHeader.deserialize(data!)!
        print(m.command)
        //print(m.payload.count)
//        let versionMessage = VersionMessage.deserialize(m.payload)
//        print("got version: \(versionMessage.version), useragent: \(versionMessage.userAgent?.value ?? "")")
    }
    
    func testHeaders() {
        // The example header with transactionCount
        // https://bitcoin.org/en/developer-reference#block-headers
        let data = Data(hex: "02000000" +   // Block version: 2
            "b6ff0b1b1680a2862a30ca44d346d9e8910d334beb48ca0c0000000000000000" +    // Hash of previous block's header
            "9d10aa52ee949386ca9385695f04ede270dda20810decd12bc9b048aaab31471" +    // Merkle root
            "24d95a54" +    // Unix time: 1415239972
            "30c31b18" +    // Target: 0x1bc330 * 256**(0x18-3)
            "fe9f0864" +    // Nonce
            "00")   // Transaction count (0x00)
        
        let header = Block.deserialize(data!)
        XCTAssertEqual(header.version, 2)
        XCTAssertEqual(header.prevBlock.hex, "b6ff0b1b1680a2862a30ca44d346d9e8910d334beb48ca0c0000000000000000")
        XCTAssertEqual(header.merkleRoot.hex, "9d10aa52ee949386ca9385695f04ede270dda20810decd12bc9b048aaab31471")
        XCTAssertEqual(header.timestamp, 1415239972)
        XCTAssertEqual(header.bits, Data(hex: "30c31b18")!.to(type: UInt32.self))
        XCTAssertEqual(header.nonce, Data(hex: "fe9f0864")!.to(type: UInt32.self))
        XCTAssertEqual(header.transactionCount.underlyingValue, 0)
        //XCTAssertTrue(header.transactions.isEmpty)
    }
    
    func testHeadersMessage2() {
        let data = Data(hex: "01000000" +
            "81cd02ab7e569e8bcd9317e2fe99f2de44d49ab2b8851ba4a308000000000000" +
            "e320b6c2fffc8d750423db8b1eb942ae710e951ed797f7affc8892b0f1fc122b" +
            "c7f5d74d" +
            "f2b9441a" +
            "42a14695")
        let hashed = Crypto.sha256sha256(data!)
        print(hashed.hex)
        
        do {
            var filter = BloomFilter(elementCount: 1, falsePositiveRate: 0.0001, randomNonce: 0)
            filter.insert(Data(hex: "019f5b01d4195ecbc9398fbf3c3b1fa9bb3183301d7a1fb3bd174fcfa40a2b65")!)
            XCTAssertEqual(Data(filter.filters).hex, "b50f")
        }
    }
    
    func test2() {
        
    }

    func test() {
        let payload = Data(hex: "00000020d4ff1c2e0d3dd47434c2ede34cbbde02be1d8c933cc871cc39cf1b00000000006d44ccc5691d8188ecdef507da2bce65dad7882c43d8ccc475d7e4c1bafb2518957f395cffff001dc8fb0c4260000000409e6aafaec5d31d470781d92b6d691c057b00cd1229462a94017e29f876025a0c5394000bdf5bbf9c639eceaafb5604e396cfe76aaca2409d2e3776b334d43e6df5219f4972708a2edcc666759e01aa0af2496f5f9542962bc9d18083ef2dfb28c3c193351a1cbe513d8e8492836ce5bb9b40b5b9de2134e00b155e7ece0d5eb726b9bb0a7f10c6c1ffc2751604996fa775223f6ba33adeb75739f58c271e174e20c361518a548b5191857ec933cb646ecc6c20bb972594ac71dcd2e1a7011e62b205865bd77299bb1321b5c1197e51304c67a1f785a65e069d8a9a2152ef6d1dd47c19be2b169a07eabcd1c9f7efe43f30707e696c6a08a9b5c218fc5991b36b4eb7fa98e4bda63c8976bd118ec33afc8eed1acbdc766c066320ae44474ee4607c3c628849239db391f9eb49ca8419da4333a3d70db4a583a6212dd4b62292d81bc88a7123eeda84db89fcccbda5a9cc62958bd1341f8c554ae55dcdd9ebb9bc3c6df0cae91c788743dc3f35de38d2dbc29c0e427ae714fa61f89d01e48eb821ffebec8450cd4dc1f1cab19b2dddfe40998cac6514aa54513d077e6ff4612ccf6a0a8078f61b3947a36ec743c2ffeddb7749996c21221fe02463d03f45311c5f21c61de988ca108c5b4b26d4bd40b034bc4206889db04606b2decfc4432b3d46307eb6c122876178a944d63fc2c39f4d6840c39c591a682243ef164939f6eb542f96b20c44fffef7d293745f8c92d4f350147b951c7e92e19a214e06991e07e27e122373888300f1ad0509f225ef20f7a9fb469b79be216d042951a9d0c48e7b97fb16d27dbcbc9ccb999bf2b6218b25bd82482db17a277ba8e1b517d9c0ee89940f1e4c71f2dd8dbc49d6aa2c93d370644d729616c399914523e83136cb142590dfbed56017ad5f1f695e8f0e346f7bfdcb3c424deaabef8d8b4e1bffa909d6b2f5d3da57086423ead5bc717ade1e612b2691973ac3596c0b8d5436d72beccb5de4c085b6663b818227192c12a90ef0197651995675f3e6c7b0b7e911aff63746de1af4a4d7b012890105adc8fcb9f49f57d1c57e80b5bc84705afd20a557ced00effbee3793635eded1c414a064210470125273332df7a20ba6febb77b613331e1b599654b97a3a67404c1fe4bbc63187523772a01d813c69ac97e0c56da492dd97754a671b52660f70a1216467f02c7e131da8895ee67e2a08b0dc49b9c07dd9eca83643141653d0b335570a5f5b71898a278585da9868525e3fb4e24d9b2f38dfe1e6e7d580a62992ce786ce6c9144e65d292a5ba50a5e8deaa05e4f53e601893418ccd7f64f63b6f4ca6614f541a9c55641333f76d7e147eb71593639eb02788b50669deeece7ac29e44d2eecf0468779ad97ae1d25ccfb97be56252fe7c3d34ac51d423a1fc53b0be6532400ac8a9b8ecc7995576a23ff43fddf8da6505d874a2691de7a480c625b40ee549d29201db719f592242a9574ea6a23ea10d4cb47facb8149c27c44d840cbfac036d8619e9b05373ed4999aa55a2dd007635aa460caf62a9a4a21581e26081076356e523a5d0f0b25fef6489d266e317da455c50ff1d4590d964755719792dcf5e9cdb6a98095b3a51a8a61882718e3a625927ad0e8b3fb9adb87c6df99c5dfbc4dc8c00a6fe4ab549148ca3700f450120a634053b4f2e68d48812f61bff72352eb7a8062042adbb2df20074a3761e0ae2aa905795503c72ab911a033e210b0ec6e9b25ef91400c404d624cb7fd7ca62f6361d0b938763b5f2c329606c58c194e54dac8378101fe5b1a872bb20e8336233ee63d482ed16ad8c303c453b5c17be959c3273c04c1a6a952d6433071453bda19d89ae4519cb93eb7251b1f31821ef72236a9e952f8be22d620455f1d6b62d996eb0f83c2e677e97916b0fcf1ddb3904a4fc5278c8e0e94510f0136769460fdcfc741cfbe19ed74623cbcca0bb4ada862746c5017360996c9de70b3b104ccc8eac49e93328a6821324671196e660a5f78d638950fff7c594596ff69f6e35eebd1d6649fadcf66ef535c0a4f54f39c1ec9d58c3a15a587135201b5f8a582daed1f73a2cd4ff28ea73e401c03aa67e7f79a1cead86e25c723f4a62bd6c5d8f193fe4fe0cf66bcafe19964397e79a9e5ee46a7b5f220ec9a4a706e98b8a13b1a10348c6b86d2b207b6a1261d4268870fa4f19aabc49a4a3ddeac3dbddee36e8a5eea2481da5df82a8242b5392d83f53b9ef5ac697b36f21b7fe25393f27dd34ccaf9459f670cbb6ea7336a053637dadf9f6afd7a86fe1f81436ec60aebffd64f39b80fd9552456ef1ca8dfc22fc205870be62ebdede4143391fa97c835a7b63eb8756631966fa557e813c5de92b512f9dd26e4f9ac94b3f157c1585d4e238ceddb8c1a11af8ab7bc5810391f171d5740c28e3f22b00e89dcb26f3e48e3411d2ee75ae5db128c522aea2f9e843528bfb005cc9ede4931e04e3e9b62d55e15518329467ef260d4535e15b0473c8f950b928e1ebc7c43fa58139eea270b3cbf1be60b022015ff537693f4d687b19bece61e3230ab12705a8c52e5f8e0edadf51ef513c6056789f9920008607a0ffdcf4966ae230b3d6ff5c9582d6d05b3d566a738dc57fdb49cfdd72f0447aa748138991095aad81027ce7eb2a2f84b11e43d9794332915a76b30bff2b18b186688d1b30cbc94753954c8d42d98c6d8eaed7848bb6d2230e7de7ec9f1af6f04aeef928e8f7e59d4594644d4071bd04b1bfeb9fb20623336b9dd3c76c15e85afa03b254e941a5ef023780e0a838c5203c0fd6bafa7001f0be03817cb5f6fd39b00bf263a87ff1b2c3870726698d647a6e63d15a26995b60dfc75f000dffb222b62974d854f5c7d397e29d48bb169fc736c220f3ff52c5193107fa7dfae6bfb6e755eaddd1ffbbad976")!
        let merkleBlock = MerkleBlockMessage.deserialize(payload)
        print("flag \(merkleBlock.flags)")
        print("totalTx: \(merkleBlock.totalTransactions), hashCount: \(merkleBlock.hashCount.underlyingValue), flagBytes: \(merkleBlock.flagBytes.underlyingValue)")
        print("isValid: \(merkleBlock.isValid())")
    }
}

