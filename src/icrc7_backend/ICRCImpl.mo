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

actor IC_ICRC7 {
    type Token = ICRC.Token;
    type TokenId = ICRC.TokenId;
    type AccountId = ICRC.AccountId;
    type Metadata = Types.MetadataDesc;
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

  public type MetadataPart = {
    purpose: MetadataPurpose;
    key_val_data: [MetadataKeyVal];
    data: Blob;
  };

  public type MetadataPurpose = {
    #Preview;
    #Rendered;
  };
  
  public type MetadataKeyVal = {
    key: Text;
    val: MetadataVal;
  };

  public type MetadataVal = {
    #TextContent : Text;
    #BlobContent : Blob;
    #NatContent : Nat;
    #Nat8Content: Nat8;
    #Nat16Content: Nat16;
    #Nat32Content: Nat32;
    #Nat64Content: Nat64;
    #IntContent: Int;
    #LinkContent: Text;
  };

  public type MintReceipt = Result<MintReceiptPart, ApiError>;

  public type MintReceiptPart = {
    token_id: TokenId;
    id: Nat;
  };

  public type TxReceipt = Result<Nat, ApiError>;
  
  public type TransactionId = Nat;

    // state
    let equalTokenId = func (a: TokenId, b: TokenId): Bool { a == b };
    let hashTokenId = func (id: TokenId): Hash.Hash { Nat32.fromNat(id) };

    stable var transactionId: TransactionId = 0;
    stable var allNfts = List.nil<Types.Nft>();
    stable var allCollections = List.nil<Types.Collection>();

    //TODO fill tokenEntries with allNfts
    // var tokenEntries = TrieMap.TrieMap<TokenId, Token>(Nat.equal, hashTokenId);

    // let ownerToTokens = TrieMap.TrieMap<AccountId, Buffer.Buffer<TokenId>>(Principal.equal, Principal.hash);

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
      let newId : TokenId = List.size(allNfts);
      let nft: Types.Nft = {
        owner = to;
        id = Nat64.fromNat(newId);
        metadata = metadata;
        tokenType = GLOBAL_TOKEN_SYMBOL;
      };
      allNfts := List.push<Nft>(nft, allNfts);
      transactionId += 1;
      // tokenEntries.put(tokenId, newToken);
      // tokens.add(tokenId);
      // ownerToTokens.put(to, tokens);
      return #Ok({
        token_id = Nat64.fromNat(newId);
        id = transactionId;
      });

        // assert(tokenEntries.get(tokenId) == null); // token must not exist
        // let newToken : Token = {
        //     id = tokenId;
        //     metadata = metadata;
        //     owner = to;
        // };
        
        // tokenEntries.put(tokenId, newToken);
        // let tokens = switch(ownerToTokens.get(to)) {
        //     case null Buffer.Buffer<TokenId>(0);
        //     case (?tokens) tokens;
        // };
        // tokens.add(tokenId);
        // ownerToTokens.put(to, tokens);
        // allNfts.add()
    };

    // public func transfer(to: AccountId, tokenId: TokenId) : () {
    //     assert(tokenEntries.contains(tokenId)); // TODO return error on token must exist

    //     let token = switch(tokenEntries.get(tokenId)) {
    //         case (?token) token;
    //         case null assert(false); // TODO return err on token doesn't exist
    //     };

    //     let prevOwner : Principal = token.owner;

    //     tokenEntries.put(tokenId, {
    //         id = tokenId;
    //         metadata = token.metadata;
    //         owner = to; 
    //     });

    //     // Update previous owner's tokens
    //     let prevTokens = switch(ownerToTokens.get(prevOwner)) {
    //         case (?tokens) {
    //                       let t : Buffer.Buffer<TokenId> = tokens;
    //                       t;};
    //         case null assert(false); // owner doesn't exist
    //     };
        
    //     let newPrevTokens = prevTokens.remove(tokenId);
    //     ownerToTokens.put(prevOwner, newPrevTokens);

    //     // Update new owner's tokens
    //     let newTokens = switch(ownerToTokens.get(to)) {
    //         case null Buffer.Buffer<TokenId>([]);
    //         case (?tokens) tokens;
    //     };
    //     Buffer.append<TokenId>(newTokens, [tokenId]);
    //     ownerToTokens.put(to, newTokens);
    // };

    // public func balanceOf(owner: AccountId) : async Nat {
    //     switch(ownerToTokens.get(owner)) {
    //         case null 0;
    //         case (?tokens) tokens.size();
    //     }
    // };

    // public func ownerOf(tokenId: TokenId) : async AccountId {
    //     switch(tokenEntries.get(tokenId)) {
    //         case (?token) token.owner;
    //         case null Principal.fromText("aaaaa-aa"); // TODO return err on token doesn't exist
    //     }
    // };

  //   public func getToken(tokenId: TokenId) : async ?Token {
  //       tokenEntries.get(tokenId);
  //   };

  // public func getTokens(start: Nat, limit: Nat) : async [Token] {
  //   var tokens = Buffer.Buffer<Token>(0);
  //   var i = start;

  //   while(i < start + limit and tokenEntries.size() > i) {
  //       switch(tokenEntries.get(i)) {
  //           case (?token) {
  //               tokens.add(token);
  //           };
  //           case _ {}
  //       };
  //       i += 1;
  //   };

//     return Buffer.toArray<Token>(tokens);
// };

  public query func balanceOf(user : Principal) : async [Nft] {
    let userNfts = List.filter(allNfts, func(nft: Nft) : Bool {
        nft.owner == user
    });
    List.toArray(userNfts);
  };

  func approve(to: AccountId, tokenId: TokenId) : () {
    // approve logic
  };

  // internal functions

  // func authorized(owner: ICRC.AccountId, tokenId: ICRC.TokenId) : Bool {
    // switch(tokenEntries.get(tokenId)) {
    //   case null { false };
    //   case (?token) { token.owner == owner }; 
    // }
  // };
  
}