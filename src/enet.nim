discard """
enet is "Copyright (c) 2002-2012 Lee Salzman"
http://enet.bespin.org/ for more information.
This wrapper was written by one called Fowl, at
or around 2012. This work is released under the
MIT license:
Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
"""

{.passL: "enet64.lib".}
{.passL: "-l winmm".}
{.passL: "-l Ws2_32".}

when defined(Linux):
  import posix

  const ENET_SOCKET_NULL*: cint = -1

  type
    ENetSocket* = cint

    ENetBuffer* {.pure, final.} = object
      data*: pointer
      dataLength*: csize_t

elif defined(Windows):
  import winlean

  let ENET_SOCKET_NULL*: cint = cast[cint](INVALID_SOCKET)

  type
    ENetSocket* = winlean.SocketHandle

    ENetBuffer* = object
      dataLength*: csize_t
      data*: pointer

const
  ENET_HOST_ANY* = 0
  ENET_HOST_BROADCAST* = 0xFFFFFFFF
  ENET_PORT_ANY* = 0
  ENET_PROTOCOL_MINIMUM_MTU* = 576
  ENET_PROTOCOL_MAXIMUM_MTU* = 4096
  ENET_PROTOCOL_MAXIMUM_PACKET_COMMANDS* = 32
  ENET_PROTOCOL_MINIMUM_WINDOW_SIZE* = 4096
  ENET_PROTOCOL_MAXIMUM_WINDOW_SIZE* = 32768
  ENET_PROTOCOL_MINIMUM_CHANNEL_COUNT* = 1
  ENET_PROTOCOL_MAXIMUM_CHANNEL_COUNT* = 255
  ENET_PROTOCOL_MAXIMUM_PEER_ID* = 0x00000FFF
  ENET_BUFFER_MAXIMUM* = (1 + 2 * ENET_PROTOCOL_MAXIMUM_PACKET_COMMANDS)
  ENET_PEER_UNSEQUENCED_WINDOW_SIZE = 1024
  ENET_PEER_RELIABLE_WINDOWS = 16

type
  ENetPeerState* {.size: sizeof(cint).} = enum
    ENET_PEER_STATE_DISCONNECTED = 0,
    ENET_PEER_STATE_CONNECTING = 1,
    ENET_PEER_STATE_ACKNOWLEDGING_CONNECT = 2,
    ENET_PEER_STATE_CONNECTION_PENDING = 3,
    ENET_PEER_STATE_CONNECTION_SUCCEEDED = 4,
    ENET_PEER_STATE_CONNECTED = 5,
    ENET_PEER_STATE_DISCONNECT_LATER = 6,
    ENET_PEER_STATE_DISCONNECTING = 7,
    ENET_PEER_STATE_ACKNOWLEDGING_DISCONNECT = 8,
    ENET_PEER_STATE_ZOMBIE = 9,

  ENetPacketFlag* {.pure, size: sizeof(cint).} = enum
    Reliable = (1 shl 0),
    Unsequenced = (1 shl 1),
    NoAllocate = (1 shl 2),
    UnreliableFragment = (1 shl 3)

  ENetPacketFreeCallback* = proc (packet: ptr ENetPacket) {.cdecl.}

  ENetPacket* {.pure, final.} = object
    referenceCount*: csize_t
    flags*: cint
    data*: cstring
    dataLength*: csize_t
    freeCallback*: ENetPacketFreeCallback

  ENetEventType* {.pure, size: sizeof(cint).} = enum
    None = 0,
    Connect = 1,
    Disconnect = 2,
    Receive = 3,

  ENetEvent* {.pure, final.} = object
    `type`*: ENetEventType
    peer*: ptr ENetPeer
    channelID*: int8
    data*: int32
    packet*: ptr ENetPacket

  ENetChecksumCallback* = proc (buffers: ptr ENetBuffer; bufferCount: csize_t): cuint {.cdecl.}

  ENetCompressor* {.pure, final.} = object
    context*: pointer
    compress*: proc (context: pointer; inBuffers: ptr ENetBuffer;
                     inBufferCount: csize_t; inLimit: csize_t;
                     outData: ptr cuchar; outLimit: csize_t): csize_t {.cdecl.}
    decompress*: proc (context: pointer; inData: ptr cuchar; inLimit: csize_t;
                       outData: ptr cuchar; outLimit: csize_t): csize_t {.cdecl.}
    destroy*: proc (context: pointer) {.cdecl.}

  ENetProtocolCommandHeader* {.pure, final.} = object
    command*: cuchar
    channelID*: cuchar
    reliableSequenceNumber*: cushort

  ENetProtocol* {.pure, final.} = object
    header*: ENetProtocolCommandHeader

  ENetAddress* {.pure, final.} = object
    host*: cuint
    port*: cushort

  ENetListNode* {.pure, final.} = object
    next*: ptr ENetListNode
    previous*: ptr ENetListNode

  ENetList* {.pure, final.} = object
    sentinel*: ENetListNode

  ENetChannel* {.pure, final.} = object
    outgoingReliableSequenceNumber*: cushort
    outgoingUnreliableSequenceNumber*: cushort
    usedReliableWindows*: cushort
    reliableWindows*: array[0..ENET_PEER_RELIABLE_WINDOWS - 1, cushort]
    incomingReliableSequenceNumber*: cushort
    incomingUnreliableSequenceNumber*: cushort
    incomingReliableCommands*: ENetList
    incomingUnreliableCommands*: ENetList

  ENetPeer* {.pure, final.} = object
    dispatchList*: ENetListNode
    host*: ptr ENetHost
    outgoingPeerID*: cushort
    incomingPeerID*: cushort
    connectID*: cuint
    outgoingSessionID*: cuchar
    incomingSessionID*: cuchar
    address*: ENetAddress
    data*: pointer
    state*: ENetPeerState
    channels*: ptr ENetChannel
    channelCount*: csize_t
    incomingBandwidth*: cuint
    outgoingBandwidth*: cuint
    incomingBandwidthThrottleEpoch*: cuint
    outgoingBandwidthThrottleEpoch*: cuint
    incomingDataTotal*: cuint
    outgoingDataTotal*: cuint
    lastSendTime*: cuint
    lastReceiveTime*: cuint
    nextTimeout*: cuint
    earliestTimeout*: cuint
    packetLossEpoch*: cuint
    packetsSent*: cuint
    packetsLost*: cuint
    packetLoss*: cuint
    packetLossVariance*: cuint
    packetThrottle*: cuint
    packetThrottleLimit*: cuint
    packetThrottleCounter*: cuint
    packetThrottleEpoch*: cuint
    packetThrottleAcceleration*: cuint
    packetThrottleDeceleration*: cuint
    packetThrottleInterval*: cuint
    lastRoundTripTime*: cuint
    lowestRoundTripTime*: cuint
    lastRoundTripTimeVariance*: cuint
    highestRoundTripTimeVariance*: cuint
    roundTripTime*: cuint
    roundTripTimeVariance*: cuint
    mtu*: cuint
    windowSize*: cuint
    reliableDataInTransit*: cuint
    outgoingReliableSequenceNumber*: cushort
    acknowledgements*: ENetList
    sentReliableCommands*: ENetList
    sentUnreliableCommands*: ENetList
    outgoingReliableCommands*: ENetList
    outgoingUnreliableCommands*: ENetList
    dispatchedCommands*: ENetList
    needsDispatch*: cint
    incomingUnsequencedGroup*: cushort
    outgoingUnsequencedGroup*: cushort
    unsequencedWindow*: array[0..ENET_PEER_UNSEQUENCED_WINDOW_SIZE div 32 - 1, cuint]
    eventData*: cuint

  ENetHost* {.pure, final.} = object
    socket*: ENetSocket
    address*: ENetAddress
    incomingBandwidth*: cuint
    outgoingBandwidth*: cuint
    bandwidthThrottleEpoch*: cuint
    mtu*: cuint
    randomSeed*: cuint
    recalculateBandwidthLimits*: cint
    peers*: ptr ENetPeer
    peerCount*: csize_t
    channelLimit*: csize_t
    serviceTime*: cuint
    dispatchQueue*: ENetList
    continueSending*: cint
    packetSize*: csize_t
    headerFlags*: cushort
    commands*: array[0..ENET_PROTOCOL_MAXIMUM_PACKET_COMMANDS - 1, ENetProtocol]
    commandCount*: csize_t
    buffers*: array[0..ENET_BUFFER_MAXIMUM - 1, ENetBuffer]
    bufferCount*: csize_t
    checksum*: ENetChecksumCallback
    compressor*: ENetCompressor
    packetData*: array[0..ENET_PROTOCOL_MAXIMUM_MTU - 1, array[0..2 - 1, cuchar]]
    receivedAddress*: ENetAddress
    receivedData*: ptr cuchar
    receivedDataLength*: csize_t
    totalSentData*: cuint
    totalSentPackets*: cuint
    totalReceivedData*: cuint
    totalReceivedPackets*: cuint

{.push cdecl, importc.}

proc enet_initialize*(): cint
proc enet_deinitialize*()
proc enet_address_set_host*(address: ptr ENetAddress, hostName: cstring): cint
proc enet_host_create*(address: ptr ENetAddress; maxConnections, maxChannels: csize_t; downSpeed, upSpeed: cuint): ptr ENetHost
proc enet_host_connect*(host: ptr ENetHost; address: ptr ENetAddress; channelCount: csize_t; data: cuint): ptr ENetPeer
proc enet_host_service*(host: ptr ENetHost; event: ptr ENetEvent; timeout: cuint): cint
proc enet_host_flush*(host: ptr ENetHost)
proc enet_peer_send*(peer: ptr ENetPeer; channel: cuchar; packet: ptr ENetPacket): cint
proc enet_host_destroy*(host: ptr ENetHost)
proc enet_peer_reset*(peer: ptr ENetPeer)
proc enet_peer_disconnect*(peer: ptr ENetPeer; a3: cuint)
proc enet_packet_create*(data: pointer; length: csize_t; flag: cuint): ptr ENetPacket
proc enet_packet_destroy*(packet: ptr ENetPacket)

{.pop.}