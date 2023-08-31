// icrc7.mo - implements the ICRC-7 standard

import ICRC "ICRC7";
import Nat "mo:base/Nat";
import Text "mo:base/Text";
import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Option "mo:base/Option";
import Time "mo:base/Time";
import TrieMap "mo:base/TrieMap";
import Hash "mo:base/Hash";
import Array "mo:base/Array";

actor IC_ICRC7 {
    type Token = ICRC.Token;
    type TokenId = ICRC.TokenId;
    type AccountId = ICRC.AccountId;
    type Metadata = ICRC.Metadata;


  // state
  stable var tokenEntries = TrieMap.TrieMap<TokenId, Token>(Nat.equal, Hash.hash);

  let ownerToTokens = TrieMap.TrieMap<AccountId, [TokenId]>(Principal.equal, Principal.hash);
  
  let approvals = TrieMap.TrieMap<TokenId, AccountId>(Nat.equal, Hash.hash);

  stable var tokensByOwnerEntries : [(AccountId, [TokenId])] = [];

  stable let name : Text = "ICRC dNFT";
  stable let symbol : Text = "ICD7";

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
      case null [];
      case (?tokens) tokens
    };
    ownerToTokens.put(to, Array.append(tokens, [tokenId]));
  };

  public func transfer(to: AccountId, tokenId: TokenId) : () {
    assert(tokenEntries.contains(tokenId)); // token must exist

    let token = switch(tokenEntries.get(tokenId)) {
      case (?token) token;
    };

    let prevOwner = token.owner;

    tokenEntries.put(tokenId, {
      id = tokenId;
      metadata = token.metadata;
      owner = to; 
    });

    // Update previous owner's tokens
    let prevTokens = switch(ownerToTokens.get(prevOwner)) {
      case (?tokens) tokens;
    };
    let newTokens = Array.filter(prevTokens, func(t) { t != tokenId });
    ownerToTokens.put(prevOwner, newTokens);

    // Update new owner's tokens
    let newToken = switch(ownerToTokens.get(to)) {
      case null [];
      case (?tokens) tokens
    };
    ownerToTokens.put(to, Array.append(newTokens, [tokenId]));

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
      case null assert(false); // token doesn't exist
    }
  };

  public func getToken(tokenId: TokenId) : async ?Token {
    tokenEntries.get(tokenId);
  };

  public func getTokens(start: Nat, limit: Nat) : async [Token] {
    var tokens : [var Token] = [];
    var i = start;

    while(i < start + limit and tokenEntries.size() > i) {
      switch(tokenEntries.get(i)) {
        case (?token) {
          tokens := Array.append(tokens, [token]);
        };
        case _ {}
      };
      i += 1;
    };

    return Array.freeze(tokens);
  };

  public func getTokensByOwner(owner: AccountId) : async [TokenId] {
    switch(ownerToTokens.get(owner)) {
      case null [];
      case (?tokens) tokens
    }
  };

  public func approve(to: AccountId, tokenId: TokenId) : () {
    // approve logic
  };

  public query func icrc7_name() : async Text {
    name;
  };

  // ...implement other ICRC-7 methods

//   public shared(msg) func icrc7_transfer(args: ICRC.TransferArgs) : async ICRC.TransferResponse {
//     if (not authorized(msg.caller, args.tokenId)) {
//       #err(#Unauthorized( args.tokenId ));
//     } else {
//       let newOwner = args.to;
//       tokensEntries.put(args.tokenId, {owner=newOwner}); 
//       tokensByOwnerEntries.put(newOwner, 
//         Array.append(tokensByOwnerEntries.get(newOwner, []), [args.tokenId]));

//       #ok(txId); // txId logic
//     };
//   };



  // internal functions

  func authorized(owner: ICRC.AccountId, tokenId: ICRC.TokenId) : Bool {
    switch(tokensEntries.get(tokenId)) {
      case null { false };
      case (?token) { token.owner == owner }; 
    }
  };

  
}