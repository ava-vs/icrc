import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import List "mo:base/List";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Time "mo:base/Time";
import TrieMap "mo:base/TrieMap";

import Types "./Types";
import ICRC "ICRC7";
import Icrc7 "ICRC7";

actor IC_ICRC7 {
    type Token = ICRC.Token;
    type TokenId = ICRC.TokenId;
    type AccountId = ICRC.AccountId;
    type Metadata = ICRC.Metadata;
    type MetadataPart = ICRC.MetadataPart;
    type Collection = ICRC.Collection;
    type CollectionMetadata = ICRC.CollectionMetadata;

    type MetadataHistory = Types.MetadataHistory;
    type MetadataLog = Types.MetadataLog;


    // state
    let equalTokenId = func (a: TokenId, b: TokenId): Bool { a == b };
    let hashTokenId = func (id: TokenId): Hash.Hash { Nat32.fromNat(id) };

    stable var transactionId: Types.TransactionId = 0;

    stable var allCollections = List.nil<ICRC.Collection>();

    stable var nftEntries : [(Principal, TokenId)] = [];

    var tokenEntries = TrieMap.TrieMap<Principal, TokenId>(Principal.equal, Principal.hash);

    stable var metadataEntries : [(TokenId, Metadata)] = [];

    var metadataMap = HashMap.fromIter<TokenId, Metadata>(metadataEntries.vals(), 1, Nat.equal, hashTokenId);
    
    stable var historyEntries : [(TokenId, MetadataHistory)] = [];

    var historyMap = HashMap.HashMap<TokenId, Buffer.Buffer<MetadataLog>>(0, Nat.equal, hashTokenId);

    let GLOBAL_TOKEN_SYMBOL = "IC7D";

    // implement ICRC-7 methods

    public func createCollection(to: AccountId, metadata: ICRC.Icrc7_collection_metadata) : async Collection {
      let defaultMetadata : CollectionMetadata = {
        icrc7_name: Text = "icrc7_name";
        icrc7_symbol: Text = "icrc7_symbol";
        icrc7_royalties: ?Nat16 = ?0;
        icrc7_royalty_recipient: ?ICRC.Account = ?{ owner = Principal.fromText("aaaaa-aa"); subaccount = ?"0"};
        icrc7_description: ?Text = ?"icrc7_description";
        icrc7_image: ?Blob = ?"img";
        icrc7_total_supply: Nat = 1;
        icrc7_supply_cap: ?Nat = ?1000;
      };
      mintCollection(to, metadata);
    };

    func mintCollection(to: Principal, metadata: ICRC.Icrc7_collection_metadata) : Collection {
      let newId : Nat = List.size(allCollections);
      let collection: Collection = {
        owner = to;
        metadata = metadata;
        id = newId;
      };
      allCollections := List.push<Collection>(collection, allCollections);
      collection;
    };

    public func mint(to: AccountId, metadata: Metadata) : async Types.MintReceipt {
      let newId : TokenId = tokenEntries.size();
      let nft: Types.DNft = {
        owner = to;
        id = newId;
        metadata = metadata;
        tokenType = GLOBAL_TOKEN_SYMBOL;
      };
      tokenEntries.put(to, nft.id);
      transactionId += 1;
      metadataMap.put(nft.id, metadata);
      updateHistory(nft.id, metadata);
      return #Ok({
        token_id = newId;
        transactionId = transactionId;
      });
    };
    
    func updateHistory(tokenId : TokenId, metadata : Metadata) : (){

      let newLog = {
        timestamp = Time.now();
        metadata = metadata; 
      };

      let newBuffer = Buffer.Buffer<MetadataLog>(0);
      newBuffer.add(newLog);

      switch(historyMap.get(tokenId)) {
        
        case (?existing) {
          existing.add(newLog);
          historyMap.put(tokenId, existing);
        };
        case (null) {
          historyMap.put(tokenId, newBuffer);
        };
      };
    };

  public func updateMetadata(user : Principal, metadata: Metadata) : async (Principal, ?Metadata) {
        var tokenId = 0;
        switch (tokenEntries.get(user)) {
          case (?token) { 
            tokenId := token;    
            switch (metadataMap.get(token)) {
              case null { 
              };
              case (?prevMetadata) {

                  var updatedMetadata = Array.thaw<MetadataPart>(prevMetadata);
                  var up : [MetadataPart] = prevMetadata;
                  for (newPart in metadata.vals()) {
                    var replaced = false;
                    for (i in Iter.range(0, prevMetadata.size() - 1)) {
                      if (metadataPartsEqual(newPart, updatedMetadata[i])) {
                        updatedMetadata[i] := newPart;
                        replaced := true;
                      };
                    };
                    if (not replaced) {
                      up := Array.append<MetadataPart>(prevMetadata, [newPart]); 
                      updateHistory(token, metadata);
                      metadataMap.put(token, up); 
                    } else {
                        updateHistory(token, metadata);
                        metadataMap.put(token, Array.freeze(updatedMetadata));
                    };
                  };                 
                };
              };            
          return (user, metadataMap.get(token));
        };
        case null {}; 
        };             
        transactionId += 1;
        (user, metadataMap.get(tokenId));
  };

/*
  When expanding the metadata composition, add cases to this method 
*/

  func metadataPartsEqual(a : MetadataPart, b : MetadataPart) : Bool {

    switch (a, b) {
      case (#TextContent(_), #TextContent(_)) {
        return true; 
      };
      case (#LinkContent(_), #LinkContent(_)) {
        return true;
      };
      case _ {
        return false;
      };
    }
  };

  public query func currentNft(user : Principal) : async Types.DNftResult {
    let token = switch (tokenEntries.get(user)) {
      case null return #Err(#NoDNFT);
      case (?t) t;
    };

    let metadata = switch (metadataMap.get(token)) {      
      case (?meta) meta;
      case null {[]};
    };

    let nft: Types.DNft = {
      owner = user;
      id = token;
      metadata = metadata;      
    };  
    #Ok(nft);
  }; 

  public query func getAllTokenIds() : async [(Principal, TokenId)] {
    Iter.toArray(tokenEntries.entries());
  };

  public query func getCollections() : async [Collection] {
    List.toArray(allCollections);
  };

  public query func getAllMetadata() : async [(TokenId, Metadata)] {
    Iter.toArray(metadataMap.entries());
  };

   public query func getFullHistory() : async [(TokenId, [MetadataLog])] {

    var newBuffer = Buffer.Buffer<(TokenId, MetadataHistory)>(historyMap.size());
    for ((tokenId, metadataLogBuffer) in historyMap.entries()) {
      newBuffer.add((tokenId, Buffer.toArray(metadataLogBuffer)));
    };
    Buffer.toArray(newBuffer);
  };

  public query func getHistoryByTokenId(tokenId : TokenId) : async (TokenId, [MetadataLog]) {
    switch (historyMap.get(tokenId)) {
      case null (tokenId, []);
      case (?log) (tokenId, Buffer.toArray<MetadataLog>(log));
    };
  };

  system func preupgrade() {
    nftEntries := Iter.toArray(tokenEntries.entries());
    metadataEntries := Iter.toArray(metadataMap.entries());
    historyEntries := [];
    var newBuffer = Buffer.Buffer<(TokenId, MetadataHistory)>(historyMap.size());
    for ((tokenId, metadataLogBuffer) in historyMap.entries()) {
      newBuffer.add((tokenId, Buffer.toArray(metadataLogBuffer)));
    };
    historyEntries := Buffer.toArray(newBuffer);
  };

  system func postupgrade() {
    for ((user, nft) in nftEntries.vals()) {
      tokenEntries.put(user, nft);
    };
    nftEntries := [];

    if (metadataMap.size() < 1)
      for ((tokenId, metadata) in metadataEntries.vals()) {
        metadataMap.put(tokenId, metadata);
      };
    metadataEntries := [];

    for ((tokenID, history) in historyEntries.vals()) {
      let arr : [MetadataLog] = history;
      let log : Buffer.Buffer<MetadataLog> = Buffer.fromArray<MetadataLog>(arr);
      historyMap.put(tokenID, log);
    };

    historyEntries := [];
  }; 
}
