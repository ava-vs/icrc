import ICRC "ICRC7";
import Nat "mo:base/Nat";
import Text "mo:base/Text";
import Principal "mo:base/Principal";
import TrieMap "mo:base/TrieMap";
import Hash "mo:base/Hash";
import Buffer "mo:base/Buffer";
import Nat32 "mo:base/Nat32";
import Array "mo:base/Array";
import List "mo:base/List";
import Types "./Types";
import Nat64 "mo:base/Nat64";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Time "mo:base/Time";

actor IC_ICRC7 {
    type Token = ICRC.Token;
    type TokenId = ICRC.TokenId;
    type AccountId = ICRC.AccountId;
    type Metadata = MetadataDesc;
    public type Result<S, E> = {
    #Ok : S;
    #Err : E;
  };
  public type ApiError = {
    #Unauthorized;
    #InvalidTokenId;
    #ZeroAddress;
    #NoNFT;
    #Other;
  };
  type Nft = Types.Nft;

  public type NftResult = Result<Types.Nft, ApiError>;
  
  public type ExtendedMetadataResult = Result<{
    metadata_desc: MetadataDesc;
    token_id: TokenId;
  }, ApiError>;

  public type MetadataResult = Result<MetadataDesc, ApiError>;

  public type MetadataDesc = [MetadataPart];

  public type MetadataLog = {
    timestamp: Time.Time;
    metadata: MetadataDesc; 
  };

  public type MetadataHistory = [MetadataLog];

  public type MetadataPart = {
    // purpose: MetadataPurpose;
    key_val_data: [MetadataKeyVal];
    // data: Blob;
  };
  
  public type MetadataKeyVal = {
    key: Text;
    val: MetadataVal;
  };

  public type MetadataVal = {
    #LinkContent: Text;
  };

  public type MintReceipt = Result<MintReceiptPart, ApiError>;

  public type MintReceiptPart = {
    token_id: TokenId;
    transactionId: Nat;
  };

  public type TxReceipt = Result<Nat, ApiError>;
  
  public type TransactionId = Nat;

  type DNft = {
    owner: Principal;
    tokenId: TokenId;
    metadata: MetadataDesc;
  };

    // state
    let equalTokenId = func (a: TokenId, b: TokenId): Bool { a == b };
    let hashTokenId = func (id: TokenId): Hash.Hash { Nat32.fromNat(id) };

    stable var transactionId: TransactionId = 0;

    stable var allCollections = List.nil<Types.Collection>();

    stable var nftEntries : [(Principal, TokenId)] = [];

    var tokenEntries = TrieMap.TrieMap<Principal, TokenId>(Principal.equal, Principal.hash);

    stable var metadataEntries : [(TokenId, Metadata)] = [];

    var metadataMap = HashMap.fromIter<TokenId, Metadata>(metadataEntries.vals(), 1, Nat.equal, hashTokenId);
    
    stable var historyEntries : [(TokenId, MetadataHistory)] = [];

    var historyMap = HashMap.HashMap<TokenId, Buffer.Buffer<MetadataLog>>(0, Nat.equal, hashTokenId);

    let GLOBAL_TOKEN_SYMBOL = "IC7D";

    // implement ICRC-7 methods

    public func createCollection(to: AccountId, metadata: ICRC.Icrc7_collection_metadata) : async Types.Collection {
      let defaultMetadata : Types.CollectionMetadata = {
        icrc7_name: Text = "icrc7_name";
        icrc7_symbol: Text = "icrc7_symbol";
        icrc7_royalties: ?Nat16 = ?0;
        icrc7_royalty_recipient: ?Types.Account = ?{ owner = Principal.fromText("aaaaa-aa"); subaccount = ?"0"};
        icrc7_description: ?Text = ?"icrc7_description";
        icrc7_image: ?Blob = ?"img";
        icrc7_total_supply: Nat = 1;
        icrc7_supply_cap: ?Nat = ?1000;
      };
      mintCollection(to, metadata);
    };

    func mintCollection(to: Principal, metadata: ICRC.Icrc7_collection_metadata) : Types.Collection {
      let newId : Nat = List.size(allCollections);
      let collection: Types.Collection = {
        owner = to;
        metadata = metadata;
        id = newId;
      };
      allCollections := List.push<Types.Collection>(collection, allCollections);
      collection;
    };

    public func mint(to: AccountId, metadata: Metadata) : async Types.MintReceipt {
      let newId : TokenId = tokenEntries.size();
      let nft: Types.Nft = {
        owner = to;
        tokenId = Nat64.fromNat(newId);
        metadata = metadata;
        tokenType = GLOBAL_TOKEN_SYMBOL;
      };
      tokenEntries.put(to, Nat64.toNat(nft.tokenId));
      transactionId += 1;
      ignore updateMetadata(to, metadata);
      return #Ok({
        token_id = Nat64.fromNat(newId);
        transactionId = transactionId;
      });
    };

  public func updateMetadata(user : Principal, metadata: Metadata) : async (Principal, ?Metadata) { 
    let tokenId : TokenId = switch (tokenEntries.get(user)) {
      case (?nft) nft;
      case null 0 ;      
    };

    metadataMap.put(tokenId, metadata);

    // History

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
    
    transactionId += 1;

    (user, metadataMap.get(tokenId));
  };

  public query func currentNft(user : Principal) : async Nft {
    let token = switch (tokenEntries.get(user)) {
      case null 0;
      case (?t) t;
    };

    let metadata = switch (metadataMap.get(token)) {      
      case (?meta) meta;
      case null {[]};
    };

    let nft: Types.Nft = {
      owner = user;
      tokenId = Nat64.fromNat(token);
      metadata = metadata;      
    };      
  }; 

  public query func getAllTokenIds() : async [(Principal, TokenId)] {
    Iter.toArray(tokenEntries.entries());
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
