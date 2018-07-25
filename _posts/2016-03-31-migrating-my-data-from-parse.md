---
title: Migrating My Data From Parse
date: 2016-03-31 09:34:25.000000000 +03:00
permalink: /migrating-my-parse-data
published: true
tags: []
---
As you probably already know, Parse announced it’s ending their hosting services on January 28, 2017. The migration plan was [divided in two steps](https://github.com/ParsePlatform/parse-server/wiki/Migrating-an-Existing-Parse-App): first, we need to host the databases of our apps, and later on we should deploy our own, open source, Parse Server. During the first stage, the clients (iOS, Android, etc.) will keep hitting Parse’s servers, and they will access the newly migrated data; after the second stage is done and your server is up and running, the clients should be updated to point to the new server. The recommended schedule by the Parse team is to migrate the database by April 28, and finish setting up your self-hosted Parse Server by July 28. Yes, you read it right - if you haven’t migrated your database, [you have less than a month to do so](https://github.com/ParsePlatform/parse-server/wiki/Migrating-an-Existing-Parse-App#what-happens-if-i-dont-migrate-my-data-by-april-28-2016).

“_But where should I start from?_”. As any decision, the pros and cons must to be taken into account, also considering the different conditions: do you have only one or multiple apps on Parse? They store huge amounts of data, or not so much? Do you have experience managing databases, specially MongoDB? How sensitive is your data? What is your budget?

As most of my apps have a small, niche audience, the amounts of data are really small. None of the databases is higher than 10 MB, even with a few thousand users, installation, and other objects. Also, most of them are free, with some humble contributions or donations occasionally. Therefore, I have a small budget to keep them functioning. As I have zero experience managing databases, I can’t build all the MongoDB server by myself (for example, I didn’t even know of some concepts like sharding, replica sets, and more). I started researching all the different options available in the market, to find what would fit my needs.

## Ok, so what are my options now?

Suggested by the Parse Team, there are [mLab](http://docs.mlab.com/migrating-from-parse/) and [ObjectRocket](https://objectrocket.com/parse), who provide - from what I’ve read - excellent DB-as-a-service. mLab would be a good fit for me, their prices start from U$15 per GB/database/month (the free tier is not intended for production usage). I have around 6 apps in production, and they require different databases, so the monthly cost would be almost U$100 per month, and we aren’t even talking about hosting the Parse Server yet. (Actually, if you are using only Parse Server, and not migrating from hosted Parse, you can use only one database for different apps, by defining a [collectionPrefix](https://github.com/ParsePlatform/parse-server/blob/ef08dcf76cb91131ff63dfbdba67a65ccf75b557/src/ParseServer.js#L70)).

Unfortunately, the prices and sizes that ObjectRocket offer aren’t for indie/side projects, so I needed to cross them as well from my list, together with mLab and [Compose.io](https://compose.io/). While reading the [community links](https://github.com/ParsePlatform/parse-server/wiki#community-links) and googling more, I’ve found [Clever Cloud](https://www.clever-cloud.com/). I almost chose them to host my DBs: you can host as many mongo dbs you want, and it’s free up to 500 MB; but if you need more than that, it jumps from a free 500 MB, to a 75 €/month for 30 GB, and I needed something in the middle.

Also, as an option for a replacement of all Parse services, there are also [NodeChef](http://nodechef.com/parse-server), [ParseGround](http://www.parseground.com/), [Backand](https://www.backand.com/parse-alternative/) and [Back4app](http://blog.back4app.com/2016/03/01/quick-wizard-migration/). But as now I have the possibility to have control over the whole parse stack, I preferred not to depend too much again on another service. It’s a personal decision; check them out because they may be a good fit for you, if you don’t want to worry at all with the backend.

After a few weeks, when I was about to give up, I found [Scalegrid.io](https://scalegrid.io), that provided exactly what I needed: a place where I can create many Mongo DBs under the same infrastructure (a cluster). Someone to manage the hard part, but with the control that I want. Similarly, there is also [MongoDB Cloud Manager](https://www.mongodb.com/migrate-from-parse-to-mongodb-cloud-manager-and-aws), which is an excellent product from MongoDB Inc. itself. I preferred to go with Scalegrid, but the process I describe in the next section is very similar for both solutions.

## Setting up my first MongoDB server

After signing up for a 30 day free trial, I checked which one of the services would fit me better: (1) hosting, where I provide my AWS keys or own hardware, and they manage it, or (2) management, where I don’t need to worry about the hardware that will host the dbs. In my case, I preferred to have control also over the underlying instances, so I chose the first option. Price-wise, they are very similar at the end of the day - in the first, you need to pay AWS and Scalegrid.io, while in the second you pay a little more but only for Scalegrid.io. According to my calculations, it would be something very close. So this is what I did, and what you should do to set it up:

1.  Create a new user the AWS account and generate the keys (Acces Key Id and Secret Acces Key). Remember to save this keys, as you won’t get them again from AWS.
2.  Created a new “Cloud Profile” in the Scalegrid console using the AWS keys.
3.  Created a new cluster using this profile. It means that the AWS EC2 instances will be created, by Scalegrid, in your AWS account. Bear in mind that you will need to choose a few options:
    1.  Size (micro gives you 10GB of storage);
    2.  The version of Mongo (Parse only supports officially 2.6 and 3.0 for now);
    3.  To enable [replica sets](https://docs.mongodb.org/manual/core/replication-introduction/) and [sharding](https://docs.mongodb.org/manual/core/sharding-introduction/) \- if you don’t have high traffic and don’t need redundancy, you probably don’t need;
    4.  To encrypt and compress the data - I suggest to set both to yes;
    5.  To enable SSL (more on the last paragraph) - it’s recommended, but not required.
4.  Wait for a few minutes (you can see the instance being created in the AWS console), and your cluster will be ready to go.
5.  Now you should be able to get the connection string, needed for migrating your Parse apps, but we are almost done.
6.  For each app, you will need a new database in your cluster. So for each app you have:
    1.  Create a new database
    2.  add a user (I called mine _parse-access_) and set a password
7.  Get the connection string, and append the database name at the end. For example, if the database name is SuperApp, your connection string should be: mongodb://user**:**password@hostaddress**:**port**/SuperApp. (the default port is 27017, and remember to append _?ssl=true_ at the end).

Finally, an important detail: as one of my apps stores medical data, I wanted SSL to be required. Scalegrid offers two options: [self-signed certificates](https://scalegrid.io/blog/mongodb-ssl-with-self-signed-certificates-in-node-js/), or use your own, trusted certificates. If you are running only your own Parse Server, the self-signed certificate is enough; if you are migrating from Parse, you will need to get a certificate from a trusted Certificate Authority, or disable SSL at all in your mongo server. I chose the first option:

1.  Purchase a certificate for a subdomain that you own:
    1.  You can get a wildcard certificate, for more than one subdomain, or get a certificate for a specific subdomain. (The latter is cheaper and may be enough, so that’s what I did: a $10 certificate via Namecheap/Comodo);
    2.  In order to create the certificate, you will need to create a .csr file. Use ssh to connect to the AWS instance and [create the .csr](https://support.comodo.com/index.php?/Default/Knowledgebase/Article/View/1/19/csr-generation-using-openssl-apache-wmod_ssl-nginx-os-x);
    3.  Provide the .csr file to the Certificate Authority;
    4.  Prove that you own the domain (this can be done by e-mail @yourdomain, or using DNS records).
    5.  In a few minutes you should receive the certificate files.
2.  In your DNS records, make the certified subdomain point to the Scalegrid server
3.  Finally, [install the certificate](https://scalegrid.io/blog/bring-your-own-ssl-certificates/) in the mongo server. (the great Scalegrid support team helped me doing so)
4.  When I thought the SSL journey was over, the migration tool from Parse still wasn’t reaching the servers, showing “No reachable servers”, because the setup wasn’t complete. After researching for a few hours, I discovered that we forgot to add the [intermediate certificate](https://uk.godaddy.com/help/what-is-an-intermediate-certificate-868).

{:refdef: style="text-align: center;"}
### I’m very happy with the solution I’ve found, but my advice to you is: **study** the available options**, define** your priorities and budget, **and start the migration process** once you chose how to store your data. Be prepared and don’t leave it to the last minute!
{:refdef}

{% include image.html name="parse-db-migrated.jpeg" %}

{:refdef: style="text-align: center;"}
If you have any troubles, you can ping me [@natanrolnik](https://www.twitter.com/natanrolnik), or e-mail me at [me+b@natanrolnik.me](mailto:me+b@natanrolnik.me).  
Thanks to [@newFosco](https://www.twitter.com/newFosco), [@MarcioK](https://www.twitter.com/MarcioK) and [@ofermorag24](https://www.twitter.com/ofermorag24)  for reviewing this post
{:refdef}

### UPDATE: 3 months after this post was published, MongoDB itself [introduced Atlas](https://www.mongodb.com/blog/post/announcing-mongodb-atlas-database-as-a-service-for-mongodb), their own hosted [MongoDB-as-a-service](https://http://mongodb.com/atlas), with an excellent [pricing](https://www.mongodb.com/cloud/atlas/pricing) and reliability. I really recommend you checking it out!
