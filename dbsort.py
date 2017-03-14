import csv
database = []
with open('raiddb.dat','rb') as f:
  reader = csv.reader(f,delimiter=',',quotechar='\"')
  for i in reader:
    database.append(i)
database.sort(key=lambda x:x[3])
with open('raiddb.dat','wb') as f:
  writer = csv.writer(f,delimiter=',',quotechar='\"')
  for i in database:
    writer.writerow(i)
print "Wrote "+str(len(database))+" rows"