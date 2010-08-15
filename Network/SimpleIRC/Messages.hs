module Network.SimpleIRC.Messages (parse) where
import Data.Maybe
import Network.SimpleIRC.Types
import qualified Data.ByteString.Char8 as B

-- PING :asimov.freenode.net
-- :haskellTestBot!~test@host86-177-151-242.range86-177.btcentralplus.com JOIN :#()

-- :dom96!~dom96@unaffiliated/dom96 PRIVMSG #() :it lives!
-- :haskellTestBot MODE haskellTestBot :+i
-- :asimov.freenode.net 376 haskellTestBot :End of /MOTD command.

-- :asimov.freenode.net 332 haskellTestBot #() :Parenthesis

-- :asimov.freenode.net 333 haskellTestBot #() Raynes!~macr0@unaffiliated/raynes 1281221819

-- |Parse a raw IRC message
parse :: B.ByteString -> IrcMessage
parse txt = 
  case length split of 2 -> (parse2 split) txt
                       3 -> (parse3 split) txt
                       4 -> (parse4 split) txt 
                       5 -> (parse5 split) txt
                       otherwise -> (parseOther split) txt
                       
  where split = smartSplit (takeCarriageRet txt)

parse4 :: [B.ByteString] -> (B.ByteString -> IrcMessage)
parse4 (first:code:chan:msg:_) = 
  let (nick, host, server) = parseFirst first
  in IrcMessage nick host server (Just code)
       (Just $ dropColon msg) (Just chan) Nothing

-- Nick, Host, Server
parseFirst :: B.ByteString -> (Maybe B.ByteString, Maybe B.ByteString, Maybe B.ByteString)
parseFirst first = 
  if '!' `B.elem` first
    then let (nick, host) = B.break (== '!') (dropColon first)
         in (Just nick, Just host, Nothing)
    else (Nothing, Nothing, Just $ dropColon first) 

dropColon :: B.ByteString -> B.ByteString
dropColon xs =
  if B.take 1 xs == (B.pack ":")
    then B.drop 1 xs
    else xs

parse2 :: [B.ByteString] -> (B.ByteString -> IrcMessage)
parse2 (code:msg:_) =
  IrcMessage Nothing Nothing Nothing (Just code)
    (Just $ dropColon msg) Nothing Nothing
    
parse3 :: [B.ByteString] -> (B.ByteString -> IrcMessage)
parse3 (first:code:msg:_) =
  let (nick, host, server) = parseFirst first
  in IrcMessage nick host server (Just code) (Just $ dropColon msg) Nothing Nothing
  
parse5 :: [B.ByteString] -> (B.ByteString -> IrcMessage)
parse5 (server:code:nick:chan:msg:_) =
  IrcMessage (Just nick) Nothing (Just server) (Just code)
    (Just $ dropColon msg) (Just chan) Nothing

parseOther :: [B.ByteString] -> (B.ByteString -> IrcMessage)
parseOther (server:code:nick:chan:other) =
  IrcMessage (Just nick) Nothing (Just server) (Just code)
    (Just $ B.unwords other)  (Just chan) (Just other)

smartSplit :: B.ByteString -> [B.ByteString]
smartSplit txt
  | ':' `B.elem` (dropColon txt) =
    let (first, msg) = B.break (== ':') (dropColon txt)
    in (B.words $ takeLast first) ++ [msg]
  | otherwise = B.words $ txt

takeLast :: B.ByteString -> B.ByteString
takeLast xs = B.take (B.length xs - 1) xs

takeCarriageRet :: B.ByteString -> B.ByteString
takeCarriageRet xs = 
  if B.drop (B.length xs - 1) xs == (B.pack "\r")
    then takeLast xs
    else xs
