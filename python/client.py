from amqplib import client_0_8 as amqp

# connect to server
lConnection = amqp.Connection(host="localhost:5672", userid="guest", password="guest", virtual_host="/", insist=False)
lChannel = lConnection.channel()

# Create queue.  Queues receive messages.
# Durable means it'll be recreated at reboot.  Auto delete of false means that it will hang
# around when all of the clients disconnect from it.  If it wasn't durable, then it would be removed when the last
# client disconnected.  If exclusive was true, then only this client would be able to see the queue.  We want
# the server to be able to put stuff into this queue, so we've set that to false.
lChannel.queue_declare(queue="myClientQueue", durable=True, exclusive=False, auto_delete=False)

# Create an exchange.  Exchanges public messages to queues
# durable and auto_delete are the same as for a queue.
# type indicates the type of exchange we want - valid values are fanout, direct, topic
#lChannel.exchange_declare(exchange="myExchange", type="direct", durable=True, auto_delete=False)
lChannel.exchange_declare(exchange="amq.direct", type="direct", durable=True, auto_delete=False)

#exchange: amq.direct, routing_key: test

# Tie the queue to the exchange.  Any messages arriving at the specified exchange
# are routed to the specified queue, but only if they arrive with the routing key specified
#lChannel.queue_bind(queue="myClientQueue", exchange="myExchange", routing_key="Test")
lChannel.queue_bind(queue="myClientQueue", exchange="amq.direct", routing_key="test")


# Define a function that is called when something is received on the queue
def data_receieved(msg):
     print 'Received: ' + msg.body

# Connect the queue to the callback function
# no_ack defaults to false.  Setting this to true means that the client will acknowledge receipt
# of the message to the server.  The message will be sent again if it isn't acknowledged.
lChannel.basic_consume(queue='myClientQueue', no_ack=True, callback=data_receieved, consumer_tag="TestTag")

# Wait for things to arrive on the queue
while True:
     lChannel.wait()

# unregister the message notification callback
# never called in this example, but this is how you do it.
lChannel.basic_cancel("TestTag")

# Close connection
lChannel.close()
lConnection.close()