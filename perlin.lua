--require "bit"

bit32 = bit

floor = math.floor

  function IntNoise_1(x,y)			  
    local n = x + y*57
    n = bit32.bxor(n*(2^13), n)
    return ( 1.0 - bit32.band((n * (n * n * 15731 + 789221) + 1376312589), 0x7fffffff) / (2*1073741824.0))    

  end

  function IntNoise_2(x,y)			 
    local n = x*59 + 2*y
    n = bit32.bxor(n*(2^13), n)
    return ( 1.0 - bit32.band((n * (n * n * 16607 + 719699) + 1200008651), 0x7fffffff) / (2*1073741824.0))

  end

  function IntNoise_3(x,y)			 
    local n = 3*x + y*47
    n = bit32.bxor(n*(2^13), n)
    return ( 1.0 - bit32.band((n * (n * n * 18127 + 700279) + 1200003533), 0x7fffffff) / (2*1073741824.0))  

  end

  function IntNoise_4(x,y)			 
    local n = x*61 + 5*y
    n = bit32.bxor(n*(2^13), n)
    return ( 1.0 - bit32.band((n * (n * n * 17327 + 702983) + 1200009823), 0x7fffffff) / (2*1073741824.0)) 

  end

  function IntNoise_5(x,y)			 
    local n = 7*x + y*53
    n = bit32.bxor(n*(2^13), n)
    return ( 1.0 - bit32.band((n * (n * n * 19259 + 708497) + 1200001339), 0x7fffffff) / (2*1073741824.0))    

  end

  function IntNoise_6(x,y)			 
    local n = x*55 + 11*y
    n = bit32.bxor(n*(2^13), n)
    return ( 1.0 - bit32.band((n * (n * n * 16057 + 709769) + 1200007087), 0x7fffffff) / (2*1073741824.0))  

  end

intnoises = {[0]=IntNoise_1,IntNoise_2,IntNoise_3,IntNoise_4,IntNoise_5,IntNoise_6}

  function Linear_Interpolate(a, b, x)
	return  a*(1-x) + b*x
  end

  function Cosine_Interpolate(a, b, x)
	local ft = x * math.pi
	local f = (1 - math.cos(ft)) * 0.5

	return  a*(1-f) + b*f
  end

  function Cubic_Interpolate(v0, v1, v2, v3,x)
	local P = (v3 - v2) - (v0 - v1)
	local Q = (v0 - v1) - P
	local R = v2 - v0
	local S = v1

	return P*x^3 + Q*x^2 + R*x + S
  end

 -- function Noise(x)

 -- end

 --[[ function SmoothNoise_1D(x)

    return Noise(x)/2  +  Noise(x-1)/4  +  Noise(x+1)/4

  end]]


 -- function Noise(x, y)

 -- end

  function SmoothNoise_2D(i,x, y)
    local Noise = intnoises[i]
    local corners = ( Noise(x-1, y-1)+Noise(x+1, y-1)+Noise(x-1, y+1)+Noise(x+1, y+1) ) / 16
    local sides   = ( Noise(x-1, y)  +Noise(x+1, y)  +Noise(x, y-1)  +Noise(x, y+1) ) /  8
    local center  =  Noise(x, y) / 4

    return corners + sides + center


  end

  function InterpolatedNoise_1D(x)	--x a float

      local integer_X    = floor(x)
      local fractional_X = x - integer_X

      local v1 = SmoothNoise1D(integer_X)
      local v2 = SmoothNoise1D(integer_X + 1)

      return Cosine_Interpolate(v1 , v2 , fractional_X)

  end

--PerlinNoise_1D ...

  function InterpolatedNoise_2D(i,x, y) --x and y floats

      local integer_X    = floor(x)
      local fractional_X = x - integer_X

      local integer_Y    = floor(y)
      local fractional_Y = y - integer_Y

      local v1 = SmoothNoise_2D(i,integer_X,     integer_Y)
      local v2 = SmoothNoise_2D(i,integer_X + 1, integer_Y)
      local v3 = SmoothNoise_2D(i,integer_X,     integer_Y + 1)
      local v4 = SmoothNoise_2D(i,integer_X + 1, integer_Y + 1)

      local i1 = Cosine_Interpolate(v1 , v2 , fractional_X)
      local i2 = Cosine_Interpolate(v3 , v4 , fractional_X)

      return Cosine_Interpolate(i1 , i2 , fractional_Y)

  end

	

persistence = 0.25
Number_Of_Octaves = 6

  function PerlinNoise_2D(x, y)	--x and y are floats	--or are they?

      local total = 0
      local p = persistence
      local n = Number_Of_Octaves - 1

      for i=0,n do

          frequency = 0.05*2^i
          amplitude = p^i

          total = total + --[[intnoises[i](floor(x*frequency),floor(y*frequency))*amplitude]] InterpolatedNoise_2D(i,x * frequency, y * frequency) * amplitude

      end

      return total

  end