

IsCorrectPath:=function(PathName)
  return PathName[Length(PathName)]='/';
end;


OrbitIntersection:=function(eSet, PermGRP)
  local eSetReturn, len1, len2, eGen;
  eSetReturn:=ShallowCopy(eSet);
  while(true)
  do
    len1:=Length(eSetReturn);
    for eGen in GeneratorsOfGroup(PermGRP)
    do
      eSetReturn:=Intersection(eSetReturn, OnSets(eSetReturn, eGen));
    od;
    len2:=Length(eSetReturn);
    if len1=len2 then
      return eSetReturn;
    fi;
  od;
end;


__FuncInvariant_Ksets:=function(DiscrSet, ListInc)
  local eInv, eO, nb, eSet;
  eInv:=[Length(ListInc)];
  for eO in DiscrSet
  do
    nb:=0;
    for eSet in eO
    do
      if IsSubset(ListInc, eSet) then
        nb:=nb+1;
      fi;
    od;
    Add(eInv, nb);
  od;
  return eInv;
end;


GetDiscriminatingSet:=function(GroupExt, nbCall)
  local TimeEvaluation, FuncGenerationRandomizedFamily, FuncComputeOdisc, TheOperatingSet, Odisc, FuncConsiderAppending, MaxSize;
  TheOperatingSet:=MovedPoints(GroupExt);
  if Length(TheOperatingSet)> 400 then
    MaxSize:=1;
  else
    MaxSize:=2;
  fi;
  TimeEvaluation:=function(DiscrSet, RandomSubsets)
    local TheDate1, TheDate2, ListOrbit, FuncInsert, eSet;
    TheDate1:=GetDate();
    ListOrbit:=[];
    FuncInsert:=function(eInc)
      local TheInv, eOrb;
      TheInv:=__FuncInvariant_Ksets(DiscrSet, eInc);
      for eOrb in ListOrbit
      do
        if TheInv=eOrb.TheInv then
          if RepresentativeAction(GroupExt, eInc, eOrb.Inc, OnSets)<>fail then
            return;
          fi;
        fi;
      od;
      Add(ListOrbit, rec(TheInv:=TheInv, Inc:=eInc));
    end;
    for eSet in RandomSubsets
    do
      FuncInsert(eSet);
    od;
    TheDate2:=GetDate();
    return TheDate2-TheDate1;
  end;
  FuncGenerationRandomizedFamily:=function(size)
    local i, a, eSub, ListSub, aSubSize, u, eG, nb1, nb2;
    a:=Length(TheOperatingSet);
    if a mod 2=0 then
      aSubSize:=a/2;
    else
      aSubSize:=(a-1)/2;
    fi;
    ListSub:=[];
    if size>50 then
      nb1:=3;
      nb2:=50;
    elif size>10 then
      nb1:=10;
      nb2:=size;
    else
      nb1:=50;
      nb2:=3;
    fi;
    for i in [1..nb1]
    do
      eSub:=RandomSubset(TheOperatingSet, aSubSize);
      for u in [1..nb2]
      do
        eG:=Random(GroupExt);
        Add(ListSub, OnSets(eSub, eG));
      od;
    od;
    return ListSub;
  end;
  FuncConsiderAppending:=function(TheOrbit, Odisc1, Ord)
    local Odisc2, ListSub, time1, time2;
    Odisc2:=ShallowCopy(Odisc1);
    Add(Odisc2, TheOrbit);
    ListSub:=FuncGenerationRandomizedFamily(Ord);
    time1:=TimeEvaluation(Odisc1, ListSub);
    time2:=TimeEvaluation(Odisc2, ListSub);
    if (time2>time1) then
      return "no";
    else
      return "yes";
    fi;
  end;
  FuncComputeOdisc:=function()
    local Odisc, iSize, O, Maxi, iOrb, Posi, UVL, eOrb, test, Ord;
    Ord:=Order(GroupExt);
    Odisc:=[];
    for iSize in [1..5]
    do
      if Length(Odisc)<10 and iSize<=MaxSize then
        O:=Orbits(GroupExt, Combinations(TheOperatingSet, iSize), OnSets);
        Maxi:=0;
        for iOrb in [1..Length(O)]
        do
          if Length(O[iOrb])>Maxi then
            Maxi:=Length(O[iOrb]);
            Posi:=iOrb;
          fi;
        od;
        UVL:=O{Difference([1..Length(O)], [Posi])};
        for eOrb in UVL
        do
          test:=FuncConsiderAppending(eOrb, Odisc, Ord);
          if test="yes" then
            Add(Odisc, eOrb);
          else
            return Odisc;
          fi;
        od;
      fi;
    od;
    return Odisc;
  end;
  if nbCall<=1000 then
    return [];
  else
    return FuncComputeOdisc();
  fi;
end;


#
#
# lift representatives of orbit for big group
# to representative for the small group.
__IndividualLifting:=function(SingleInc, SmallGroup, BigGroup)
  local PartialNewList, StabBig, eDCS;
  PartialNewList:=[];
  StabBig:=Stabilizer(BigGroup, SingleInc, OnSets);
  for eDCS in DoubleCosets(BigGroup, StabBig, SmallGroup)
  do
    Add(PartialNewList, OnSets(SingleInc, Representative(eDCS)));
  od;
  return PartialNewList;
end;


GlobalLiftingOrbitsOnSets:=function(ListInc, SmallGroup, BigGroup)
  local NewListInc, eInc;
  # this ansatz below can speed things up very significantly.
  if Order(SmallGroup)=Order(BigGroup) then
    return ListInc;
  fi;
  NewListInc:=[];
  for eInc in ListInc
  do
    Append(NewListInc, __IndividualLifting(eInc, SmallGroup, BigGroup));
  od;
  return NewListInc;
end;


POLY_GetFunctionSet_MinimumOrbit:=function(EXT, TheGroup)
  local FuncGetInitialDisc, FuncInvariant, FuncIsomorphy, FuncInvariantUpdate, OrderLincStabilizer, GetOrbitIntersection;
  FuncGetInitialDisc:=function()
    return [];
  end;
  FuncInvariant:=function(Odisc, Linc)
    return Minimum(Orbit(TheGroup, Linc, OnSets));
  end;
  FuncIsomorphy:=function(Linc1, Linc2)
    return true;
  end;
  FuncInvariantUpdate:=function(OdiscPrev, nbCall)
    return [];
  end;
  OrderLincStabilizer:=function(Linc)
    return Order(Stabilizer(TheGroup, Linc, OnSets));
  end;
  GetOrbitIntersection:=function(eSet)
    return OrbitIntersection(eSet, TheGroup);
  end;
  return rec(FuncGetInitialDisc:=FuncGetInitialDisc,
             FuncInvariant:=FuncInvariant,
             FuncIsomorphy:=FuncIsomorphy,
             GroupOrder:=Order(TheGroup),
             OrderLincStabilizer:=OrderLincStabilizer,
             GetOrbitIntersection:=GetOrbitIntersection,
             FuncInvariantUpdate:=FuncInvariantUpdate);
end;


POLY_GetFunctionSet_Backtrack:=function(EXT, TheGroup)
  local FuncGetInitialDisc, FuncInvariant, FuncIsomorphy, FuncInvariantUpdate, OrderLincStabilizer, GetOrbitIntersection;
  FuncGetInitialDisc:=function()
    return [];
  end;
  FuncInvariant:=function(Odisc, Linc)
    return __FuncInvariant_Ksets(Odisc, Linc);
  end;
  FuncIsomorphy:=function(Linc1, Linc2)
    return RepresentativeAction(TheGroup, Linc1, Linc2, OnSets)<>fail;
  end;
  FuncInvariantUpdate:=function(OdiscPrev, NbCall)
    if NbCall=1001 then
      return GetDiscriminatingSet(TheGroup, NbCall);
    else
      return OdiscPrev;
    fi;
  end;
  OrderLincStabilizer:=function(Linc)
    return Order(Stabilizer(TheGroup, Linc, OnSets));
  end;
  GetOrbitIntersection:=function(eSet)
    return OrbitIntersection(eSet, TheGroup);
  end;
  return rec(FuncGetInitialDisc:=FuncGetInitialDisc,
             FuncInvariant:=FuncInvariant,
             FuncIsomorphy:=FuncIsomorphy,
             GroupOrder:=Order(TheGroup),
             OrderLincStabilizer:=OrderLincStabilizer,
             GetOrbitIntersection:=GetOrbitIntersection,
             FuncInvariantUpdate:=FuncInvariantUpdate);
end;


POLY_GetFunctionSet_MatrixInvariant:=function(EXT, TheGroup, TheLimit)
  local FuncGetInitialDisc, FuncInvariant, FuncIsomorphy, FuncInvariantUpdate, OrderLincStabilizer, GetOrbitIntersection;
  FuncGetInitialDisc:=function()
    return __VectorConfiguration_Invariant_GetTools(EXT, TheLimit);
  end;
  FuncInvariant:=function(Odisc, Linc)
    return __VectorConfiguration_Invariant_ComputeAdvanced(Odisc, Linc);
  end;
  FuncIsomorphy:=function(Linc1, Linc2)
    return RepresentativeAction(TheGroup, Linc1, Linc2, OnSets)<>fail;
  end;
  FuncInvariantUpdate:=function(OdiscPrev, NbCall)
    return OdiscPrev;
  end;
  OrderLincStabilizer:=function(Linc)
    return Order(Stabilizer(TheGroup, Linc, OnSets));
  end;
  GetOrbitIntersection:=function(eSet)
    return OrbitIntersection(eSet, TheGroup);
  end;
  return rec(FuncGetInitialDisc:=FuncGetInitialDisc,
             FuncInvariant:=FuncInvariant,
             FuncIsomorphy:=FuncIsomorphy,
             GroupOrder:=Order(TheGroup),
             OrderLincStabilizer:=OrderLincStabilizer,
             GetOrbitIntersection:=GetOrbitIntersection,
             FuncInvariantUpdate:=FuncInvariantUpdate);
end;


OrbitGroupFormalism:=function(EXT, TheGroup, Prefix, SavingTrigger, TheFormalism)
  local TotalNumber, nbUndone, nbOrbit, nbOrbitDone, ListOrbit, FuncGetMinimalUndoneOrbit, FuncInsert, FuncPutOrbitAsDone, FuncListOrbitIncidence, FuncRecord, FuncDirectAppend, FuncNumber, FuncNumberUndone, FuncNumberOrbit, FuncNumberOrbitDone, FileDatabaseCoherent, NbCall, FileNbCall, FileDisc, LoadListOrbit, InvariantUpdate, Odisc, FuncClearFiles, ComputeIntersectionUndone, RbalinskiRank, ComputeRankUndone;
  if IsCorrectPath(Prefix)=false then
    Error("Variable Prefix=", Prefix, " should terminate with /");
  fi;
  if IsDirectoryPath(Prefix)=false and SavingTrigger then
    Error("Directory Prefix=", Prefix, " is nonexistent\n");
  fi;
  FileDatabaseCoherent:=Concatenation(Prefix, "Coherent");
  FileNbCall:=Concatenation(Prefix, "NbCall");
  FileDisc:=Concatenation(Prefix, "Discriminant");
  TotalNumber:=0;
  nbUndone:=0;
  nbOrbit:=0;
  nbOrbitDone:=0;
  ListOrbit:=[];
  NbCall:=0;
  #
  #
  # For a polytope P the set of vertices not contained in a face F
  # is connected.
  # Furthermore any vertex in F is adjacent to at least one vertex not
  # in F.
  # This gives a criterion analog to Balinski theorem that we need
  # to program here.
  FuncClearFiles:=function()
    local FileName, File1, File2, File1touch, File2touch, iOrb;
    RemoveFile(FileDatabaseCoherent);
    RemoveFileIfExistPlusTouch(Concatenation(FileDisc, "_1"));
    RemoveFileIfExistPlusTouch(Concatenation(FileDisc, "_2"));
    RemoveFileIfExistPlusTouch(Concatenation(FileNbCall, "_1"));
    RemoveFileIfExistPlusTouch(Concatenation(FileNbCall, "_2"));
    iOrb:=1;
    while(true)
    do
      FileName:=Concatenation(Prefix, "Orbit", String(iOrb));
      File1:=Concatenation(FileName, "_1");
      File2:=Concatenation(FileName, "_2");
      File1touch:=Concatenation(File1, "_touch");
      File2touch:=Concatenation(File2, "_touch");
      if IsExistingFile(File1) or IsExistingFile(File2) or IsExistingFile(File1touch) or IsExistingFile(File2touch) then
        RemoveFileIfExist(File1);
        RemoveFileIfExist(File2);
        RemoveFileIfExist(File1touch);
        RemoveFileIfExist(File2touch);
      else
        break;
      fi;
      iOrb:=iOrb+1;
    od;
  end;
  FuncDirectAppend:=function(WList)
    local eOrb;
    Append(ListOrbit, WList);
    for eOrb in WList
    do
      TotalNumber:=TotalNumber+eOrb.OrbSize;
      if eOrb.Status="YES" then
        nbOrbitDone:=nbOrbitDone+1;
      else
        nbUndone:=nbUndone+eOrb.OrbSize;
      fi;
      nbOrbit:=nbOrbit+1;
    od;
  end;
  LoadListOrbit:=function()
    local iOrb, WList, FileOrbit, LDR;
    iOrb:=1;
    WList:=[];
    while(true)
    do
      FileOrbit:=Concatenation(Prefix, "Orbit", String(iOrb));
      if IsExistingFileRecoverablePrevState(FileOrbit) then
        LDR:=ReadAsFunctionRecoverablePrevState(FileOrbit);
        Add(WList, LDR);
        iOrb:=iOrb+1;
      else
        break;
      fi;
    od;
    FuncDirectAppend(WList);
  end;
  if SavingTrigger then
    if IsExistingFile(FileDatabaseCoherent)=false then
      Print("The database is not coherent, clear it\n");
      FuncClearFiles();
      Odisc:=TheFormalism.FuncGetInitialDisc();
      SaveDataToFileRecoverablePrevState(FileDisc, Odisc);
      SaveDataToFileRecoverablePrevState(FileNbCall, NbCall);
      SaveDataToFile(FileDatabaseCoherent, 0);
    else
      Print("The database is coherent, load it\n");
      Odisc:=ReadAsFunctionRecoverablePrevState(FileDisc);
      LoadListOrbit();
      NbCall:=ReadAsFunctionRecoverablePrevState(FileNbCall);
    fi;
  else
    Odisc:=TheFormalism.FuncGetInitialDisc();
  fi;
  InvariantUpdate:=function()
    local iOrb, FileOrbit;
    if SavingTrigger then
      Print("Beginning invariant update, please keep program running\n");
      RemoveFile(FileDatabaseCoherent);
    fi;
    if SavingTrigger then
      SaveDataToFileRecoverablePrevState(FileDisc, Odisc);
    fi;
    for iOrb in [1..Length(ListOrbit)]
    do
      ListOrbit[iOrb].TheInv:=TheFormalism.FuncInvariant(Odisc, ListOrbit[iOrb].Inc);
      if SavingTrigger then
        FileOrbit:=Concatenation(Prefix, "Orbit", String(iOrb));
        SaveDataToFileRecoverablePrevState(FileOrbit, ListOrbit[iOrb]);
      fi;
    od;
    if SavingTrigger then
      SaveDataToFile(FileDatabaseCoherent, 0);
      Print("Invariant update finished\n");
    fi;
  end;
  FuncInsert:=function(Linc)
    local eOrb, TheInv, iExt, FileOrbit, TheRecord, OrdStab, OrbSize, OdiscNew;
    NbCall:=NbCall+1;
    if NbCall mod 20=0 then
      SaveDataToFileRecoverablePrevStatePlusTest(FileNbCall, NbCall, SavingTrigger);
    fi;
    OdiscNew:=TheFormalism.FuncInvariantUpdate(Odisc, NbCall);
    if OdiscNew<>Odisc then
      Odisc:=OdiscNew;
      InvariantUpdate();
    fi;
    TheInv:=TheFormalism.FuncInvariant(Odisc, Linc);
    for eOrb in ListOrbit
    do
      if TheInv=eOrb.TheInv then
        if TheFormalism.FuncIsomorphy(Linc, eOrb.Inc) then
          return;
        fi;
      fi;
    od;
    FileOrbit:=Concatenation(Prefix, "Orbit", String(Length(ListOrbit)+1));
    OrdStab:=TheFormalism.OrderLincStabilizer(Linc);
    OrbSize:=TheFormalism.GroupOrder/OrdStab;
    TheRecord:=rec(Inc:=Linc, TheInv:=TheInv, Status:="NO", OrbSize:=OrbSize);
    TotalNumber:=TotalNumber+OrbSize;
    nbUndone:=nbUndone+OrbSize;
    nbOrbit:=nbOrbit+1;
    Add(ListOrbit, TheRecord);
    SaveDataToFileRecoverablePrevStatePlusTest(FileOrbit, TheRecord, SavingTrigger);
  end;
  FuncPutOrbitAsDone:=function(iOrb)
    local FileOrbit;
    ListOrbit[iOrb].Status:="YES";
    FileOrbit:=Concatenation(Prefix, "Orbit", String(iOrb));
    SaveDataToFileRecoverablePrevStatePlusTest(FileOrbit, ListOrbit[iOrb], SavingTrigger);
    nbUndone:=nbUndone-ListOrbit[iOrb].OrbSize;
    nbOrbitDone:=nbOrbitDone+1;
  end;
  ComputeIntersectionUndone:=function()
    local iOrb, IsFirst, eSetReturn;
    IsFirst:=true;
    for iOrb in [1..nbOrbit]
    do
      if ListOrbit[iOrb].Status="NO" then
        if IsFirst then
          eSetReturn:=TheFormalism.GetOrbitIntersection(ListOrbit[iOrb].Inc);
        else
          eSetReturn:=Intersection(eSetReturn, TheFormalism.GetOrbitIntersection(ListOrbit[iOrb].Inc));
        fi;
        if Length(eSetReturn)=0 then
          return eSetReturn;
        fi;
        IsFirst:=false;
      fi;
    od;
    if IsFirst then
      return [];
    fi;
    return eSetReturn;
  end;
  FuncListOrbitIncidence:=function()
    if SavingTrigger then
      FuncClearFiles();
    fi;
    return List(ListOrbit, x->x.Inc);
  end;
  FuncRecord:=function(iOrb)
    return ListOrbit[iOrb].Inc;
  end;
  FuncNumber:=function()
    return TotalNumber;
  end;
  FuncNumberUndone:=function()
    return nbUndone;
  end;
  FuncNumberOrbit:=function()
    return nbOrbit;
  end;
  FuncNumberOrbitDone:=function()
    return nbOrbitDone;
  end;
  FuncGetMinimalUndoneOrbit:=function()
    local MiniINCD, eINCD, SelectedOrbit, jOrb, eOrb;
    MiniINCD:=Length(EXT);
    SelectedOrbit:=-1;
    for jOrb in [1..nbOrbit]
    do
      eOrb:=ListOrbit[jOrb];
      if eOrb.Status="NO" then
        eINCD:=Length(eOrb.Inc);
        if eINCD < MiniINCD then
          MiniINCD:=eINCD;
          SelectedOrbit:=jOrb;
        fi;
      fi;
    od;
    return SelectedOrbit;
  end;
  return rec(FuncInsert:=FuncInsert,
             FuncListOrbitIncidence:=FuncListOrbitIncidence,
             FuncRecord:=FuncRecord,
             ComputeIntersectionUndone:=ComputeIntersectionUndone,
             FuncPutOrbitAsDone:=FuncPutOrbitAsDone,
             FuncNumber:=FuncNumber,
             FuncNumberUndone:=FuncNumberUndone,
             FuncGetMinimalUndoneOrbit:=FuncGetMinimalUndoneOrbit,
             FuncNumberOrbit:=FuncNumberOrbit,
             FuncNumberOrbitDone:=FuncNumberOrbitDone);
end;


#
#
# For isomorphy tests in the ADM, we can choose a different
# group formalism. This can help speed up performance.
# see below the standard PermutationGroup + OnSets formalism
OnSetsGroupFormalism:=function(LimitNbVert)
  local __LiftingOrbits, OnSetsRepresentativeAction, OnSetsStabilizer, GroupUnion, ToPermGroup, TheOrder, OnSetsIsSubgroup, OnSetsGroupConjugacy, OnSetsTransformIncidenceList, MyOrbitGroupFormalism, BankKeyInformation, BankCompleteInformation, BankGetVertexSet, BankGetGroup, BankGetListObject, BankGetForIsom, GetOrbitIntersection;
  __LiftingOrbits:=function(EXT, ListInc, SmallGroup, BigGroup)
    return GlobalLiftingOrbitsOnSets(ListInc, SmallGroup, BigGroup);
  end;
  OnSetsStabilizer:=function(EXT, GRP, eInc)
    return SecondReduceGroupAction(Stabilizer(GRP, eInc, OnSets), eInc);
  end;
  GroupUnion:=function(Grp1, Grp2)
    local ListGen, ListGenSmall;
    ListGen:=Union(GeneratorsOfGroup(Grp1), GeneratorsOfGroup(Grp2));
    if Length(ListGen)=0 then
      return Grp1;
    fi;
    ListGenSmall:=SmallGeneratingSet(Group(ListGen));
    if Length(ListGenSmall)=0 then
      return Grp1;
    fi;
    return Group(ListGenSmall);
  end;
  ToPermGroup:=function(EXT, Grp)
    return Grp;
  end;
  TheOrder:=function(GRP)
    return Order(GRP);
  end;
  OnSetsIsSubgroup:=function(GRP1, GRP2)
    return IsSubgroup(GRP1, GRP2);
  end;
  OnSetsGroupConjugacy:=function(GRP, eElt)
    local NewGens, eGen;
    NewGens:=[];
    for eGen in GeneratorsOfGroup(GRP)
    do
      Add(NewGens, eElt^(-1)*eGen*eElt);
    od;
    return PersoGroupPerm(NewGens);
  end;
  OnSetsTransformIncidenceList:=function(ListEXT1, ListEXT2, TheEquiv, ListListInc)
    return List(ListListInc, x->OnSets(x, TheEquiv));
  end;
  MyOrbitGroupFormalism:=function(EXT, TheGroup, Prefix, SavingTrigger)
    local LFC;
    if Order(TheGroup)<=14500 then
      LFC:=POLY_GetFunctionSet_MinimumOrbit(EXT, TheGroup);
    else
#      LFC:=POLY_GetFunctionSet_Backtrack(EXT, TheGroup);
      LFC:=POLY_GetFunctionSet_MatrixInvariant(EXT, TheGroup, LimitNbVert);
    fi;
    return OrbitGroupFormalism(EXT, TheGroup, Prefix, SavingTrigger, LFC);
  end;
  BankKeyInformation:=function(EXT, GroupExt)
    return rec(EXT:=EXT, Group:=GroupExt);
  end;
  BankCompleteInformation:=function(EXT, GroupExt, ListObject)
    return ListObject;
  end;
  BankGetVertexSet:=function(TheKey, TheComplete)
    return TheKey.EXT;
  end;
  BankGetGroup:=function(TheKey, TheComplete)
    return TheKey.Group;
  end;
  BankGetListObject:=function(TheComplete)
    return TheComplete;
  end;
  BankGetForIsom:=function(TheKey)
    return TheKey.EXT;
  end;
  return rec(
    Stabilizer:=OnSetsStabilizer,
    LiftingOrbits:=__LiftingOrbits,
    GroupUnion:=GroupUnion,
    ToPermGroup:=ToPermGroup,
    Order:=TheOrder,
    IsSubgroup:=OnSetsIsSubgroup,
    GroupConjugacy:=OnSetsGroupConjugacy,
    TransformIncidenceList:=OnSetsTransformIncidenceList,
    OrbitGroupFormalism:=MyOrbitGroupFormalism,
    BankKeyInformation:=BankKeyInformation,
    BankCompleteInformation:=BankCompleteInformation,
    BankGetForIsom:=BankGetForIsom,
    BankGetVertexSet:=BankGetVertexSet,
    BankGetGroup:=BankGetGroup,
    BankGetListObject:=BankGetListObject);
end;