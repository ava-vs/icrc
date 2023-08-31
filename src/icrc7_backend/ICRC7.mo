import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Nat "mo:base/Nat";

module ICRC7 {

  public type AccountId = Principal;

  public type TokenId = Nat;

  public type Metadata = {
    #Nat : Nat;
    #Int : Int;
    #Text : Text;
    #Blob : Blob;
  };

  public type Token = {
    id : TokenId;
    metadata : Metadata;
    owner : AccountId;
  };

}