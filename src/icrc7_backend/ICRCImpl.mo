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

actor IC_ICRC7 {
    type Token = ICRC.Token;
    type TokenId = ICRC.TokenId;
    type AccountId = ICRC.AccountId;
    type Metadata = ICRC.Metadata;
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
  public type Nft = {
    owner: Principal;
    id: TokenId;
    metadata: MetadataDesc;
  };

  public type NftResult = Result<Nft, ApiError>;
  
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
    stable var allNfts = List.nil<Nft>();

    //TODO fill tokenEntries with allNfts
    var tokenEntries = TrieMap.TrieMap<TokenId, Token>(Nat.equal, hashTokenId);
    
    let ownerToTokens = TrieMap.TrieMap<AccountId, Buffer.Buffer<TokenId>>(Principal.equal, Principal.hash);

    // implement ICRC-7 methods

    public func mint(to: AccountId, tokenId: TokenId, metadata: Metadata) : () {
        assert(tokenEntries.get(tokenId) == null); // token must not exist
        let newToken : Token = {
            id = tokenId;
            metadata = metadata;
            owner = to;
        };
        
        tokenEntries.put(tokenId, newToken);
        let tokens = switch(ownerToTokens.get(to)) {
            case null Buffer.Buffer<TokenId>(0);
            case (?tokens) tokens;
        };
        tokens.add(tokenId);
        ownerToTokens.put(to, tokens);
    };

    public func transfer(to: AccountId, tokenId: TokenId) : () {
        assert(tokenEntries.contains(tokenId)); // TODO return error on token must exist

        let token = switch(tokenEntries.get(tokenId)) {
            case (?token) token;
            case null assert(false); // TODO return err on token doesn't exist
        };

        let prevOwner : Principal = token.owner;

        tokenEntries.put(tokenId, {
            id = tokenId;
            metadata = token.metadata;
            owner = to; 
        });

        // Update previous owner's tokens
        let prevTokens = switch(ownerToTokens.get(prevOwner)) {
            case (?tokens) {
                          let t : Buffer.Buffer<TokenId> = tokens;
                          t;};
            case null assert(false); // owner doesn't exist
        };
        
        let newPrevTokens = prevTokens.remove(tokenId);
        ownerToTokens.put(prevOwner, newPrevTokens);

        // Update new owner's tokens
        let newTokens = switch(ownerToTokens.get(to)) {
            case null Buffer.Buffer<TokenId>([]);
            case (?tokens) tokens;
        };
        Buffer.append<TokenId>(newTokens, [tokenId]);
        ownerToTokens.put(to, newTokens);
    };

    public func balanceOf(owner: AccountId) : async Nat {
        switch(ownerToTokens.get(owner)) {
            case null 0;
            case (?tokens) tokens.size();
        }
    };

    public func ownerOf(tokenId: TokenId) : async AccountId {
        switch(tokenEntries.get(tokenId)) {
            case (?token) token.owner;
            case null Principal.fromText("aaaaa-aa"); // TODO return err on token doesn't exist
        }
    };

    public func getToken(tokenId: TokenId) : async ?Token {
        tokenEntries.get(tokenId);
    };


  public func getTokens(start: Nat, limit: Nat) : async [Token] {
    var tokens = Buffer.Buffer<Token>(0);
    var i = start;

    while(i < start + limit and tokenEntries.size() > i) {
        switch(tokenEntries.get(i)) {
            case (?token) {
                tokens.add(token);
            };
            case _ {}
        };
        i += 1;
    };

    return Buffer.toArray<Token>(tokens);
};


  public func getTokensByOwner(owner: AccountId) : async [TokenId] {
    switch(ownerToTokens.get(owner)) {
      case null [];
      case (?tokens) return tokens;
    }
  };

  public func approve(to: AccountId, tokenId: TokenId) : () {
    // approve logic
  };

  // internal functions

  func authorized(owner: ICRC.AccountId, tokenId: ICRC.TokenId) : Bool {
    switch(tokenEntries.get(tokenId)) {
      case null { false };
      case (?token) { token.owner == owner }; 
    }
  };

  
}