
module myPSS

#
#  https://ntrs.nasa.gov/citations/19860015695
#


using ControlSystemsBase
using OrderedCollections: OrderedDict
using Modia
@usingModiaPlot


include("utilsPSS.jl")


function PSS2Binit(para)

    evalVar = NumParametersForInit(para)   # get all numerical parameters from model
    eval(evalVar)
# println(evalVar)

    # wash out  A_omega B_power
    aw = tf([Tw1,0],[Tw1,1]) * tf([Tw2,0],[Tw2,1]) * tf([1.0],[T6,1])
    bw = tf([Tw3,0],[Tw3,1]) * tf([Ks2],[T7,1])
    ## ramp tracking
    rt =  tf([1],[T9,1])^M * tf([T8,1],[1])
    # phase comp
    pc = tf([T1,1],[T2,1]) * tf([T3,1],[T4,1])

    Saw = StateSpace(aw)
    Sbw = StateSpace(bw)
    Srt = StateSpace(rt)
    Spc = StateSpace(pc)


    # input #1 speed
    # input #2 power
    # overall system has 2 inputs and 1 output. extend SS -> 2 inputs
    Saw = StateSpace(Saw.A, [Saw.B zeros(Saw.nx,1)], Saw.C, [Saw.D  0]) # input #2 = dummy
    Sbw = StateSpace(Sbw.A, [zeros(Sbw.nx,1) Sbw.B], Sbw.C, [0 Sbw.D ]) # input #1 = dummy

    R1 = SummationCommon(Saw,1.0,1.0,Sbw,Ks3)
    R2 = Concatenation(R1,1.0,1.0,Srt)
    R3 = SummationCommon(R2,1.0,1.0,Sbw,-1.0)
    R4 = Concatenation(R3,Ks1,1.0,Spc)

    x0 = -R4.A\(R4.B*[w0;p0])   # inital values

    p = para[:system]
    p[:A] = R4.A
    p[:B] = R4.B
    p[:C] = R4.C
    p[:D] = R4.D
    p[:x] = vec(x0)

    (Saw,Sbw,Srt,Spc)
end




# Tw = 10
# Inertia = 3091
# H2 = Inertia/314.15
# N = 1
# M = 5
# T9 = 0.1
# T8 = M*T9
# Tw1 = Tw;   Tw2 = Tw;   Tw3 = Tw
# T1 = 0.11; T2 = 0.02;  T3 = 0.11;   T4 = 0.02
# T6 = 0;    T7 = Tw;
# Ks1 = 20;   Ks2 = Tw/H2;  Ks3 = 1;



PSS2Btest = Model(
    initFktL1 = IniFkt(fktcall=PSS2Binit),


    Tw1 = 10.0, Tw2 = 10.0, Tw3 = 10.0,
    T1 = 0.11,  T2 = 0.02,  T3 = 0.11,  T4 = 0.02,
    T6 = 0.0,   T7 = 10.0,
    M = 5,
    T8 = 5*0.1, T9 = 0.1,
    Ks1 = 20.0, Ks2 = 1.0163377547719183,   Ks3 = 1.0,
    # start
    p0 = 0.5,   w0 = 0.0,
    # limiter
    Vstmin = -0.05,     Vstmax = 0.1,   #TODO

    out = output,
    system = SS,

    equations = :[
        system.u = [w0, p0+0.01*time]
        out = system.y[1,1]
    ]
)


instModel = @instantiateModel(PSS2Btest,
    unitless=true,
    log=false,
    logTiming=false,
    logDetails=false,
    logCode=false,
    logFile=false,
    logStateSelection=false,
    evaluateParameters=false,
#         saveCodeOnFile="CODE.txt.jl",
)



(Saw,Sbw,Srt,Spc) = PSS2Btest[:initFktL1][:fktcall](instModel.parameters)


@time simulate!(instModel, interval = 0.01, stopTime=5.0)
@time simulate!(instModel, interval = 0.01, stopTime=5.0)
@time simulate!(instModel, interval = 0.01, stopTime=5.0)
@time simulate!(instModel, interval = 0.01, stopTime=5.0)
@time simulate!(instModel, interval = 0.01, stopTime=5.0)
println()

plot(instModel, [("out")], figure = 1)



end
