
local entries   = ARGV[1]
local precision = ARGV[2]
local index     = math.ceil(redis.call('INCR', KEYS[1] .. ':count') / entries)
local key       = KEYS[1] .. ':' .. index

-- Based on the math from: http://en.wikipedia.org/wiki/Bloom_filter#Probability_of_false_positives
-- Combined with: http://www.sciencedirect.com/science/article/pii/S0020019006003127
-- 0.480453013 = ln(2)^2
local bits = math.floor(-(entries * math.log(precision * math.pow(0.5, index))) / 0.480453013)

-- 0.693147180 = ln(2)
local k = math.floor(0.693147180 * bits / entries)

local hash = redis.sha1hex(ARGV[3])

-- This uses a variation on:
-- 'Less Hashing, Same Performance: Building a Better Bloom Filter'
-- http://www.eecs.harvard.edu/~kirsch/pubs/bbbf/esa06.pdf
local h = { }
h[0] = tonumber(string.sub(hash, 0 , 8 ), 16)
h[1] = tonumber(string.sub(hash, 8 , 16), 16)
h[2] = tonumber(string.sub(hash, 16, 24), 16)
h[3] = tonumber(string.sub(hash, 24, 32), 16)

for i=1, k do
  redis.call('SETBIT', key, (h[i % 2] + i * h[2 + (((i + (i % 2)) % 4) / 2)]) % bits, 1)
end

