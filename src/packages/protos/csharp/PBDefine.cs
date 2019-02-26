using Google.Protobuf;
using System.Collections.Generic;
namespace Pb{
    public enum PBDefine{
        Unknow,
        Pack = 1,
        Error = 2,
        Operation = 3,
        CreateRole = 4,
        FinishChapter = 5,
        OpenBox = 31,
        GainBox = 32,
        Delete = 11,
        Role = 101,
        Prop = 1071,
        Props = 107,
        Chapter = 1021,
        Chapters = 102,
        GameRecord = 112,
        FinishMission = 51,
        FinishAchv = 53,
        MissionEvent = 52,
        MissionItem = 1051,
        MissionList = 105,
        AchvItem = 1091,
        AchvList = 109,
        Box = 1061,
        Boxes = 106,
        Rewards = 108,
        Talents = 110,
        TalentUnlock = 54,
        SigninRecord = 12,
        SigninGet = 13,
        ShopBuy = 22,
        ADShow = 41,
        ADList = 111,
        ShopRecord = 21,
        RecordSave = 51,
        MapRecordSave = 15
    }

    public static class PBRegister
    {
        public static void Register(ref Dictionary<PBDefine, MessageParser>dict)
        {
            dict.Add(PBDefine.Pack, Pack.Parser);
            dict.Add(PBDefine.Error, Error.Parser);
            dict.Add(PBDefine.Operation, Operation.Parser);
            dict.Add(PBDefine.CreateRole, CreateRole.Parser);
            dict.Add(PBDefine.FinishChapter, FinishChapter.Parser);
            dict.Add(PBDefine.OpenBox, OpenBox.Parser);
            dict.Add(PBDefine.GainBox, GainBox.Parser);
            dict.Add(PBDefine.Delete, Delete.Parser);
            dict.Add(PBDefine.Role, Role.Parser);
            dict.Add(PBDefine.Prop, Prop.Parser);
            dict.Add(PBDefine.Props, Props.Parser);
            dict.Add(PBDefine.Chapter, Chapter.Parser);
            dict.Add(PBDefine.Chapters, Chapters.Parser);
            dict.Add(PBDefine.GameRecord, GameRecord.Parser);
            dict.Add(PBDefine.FinishMission, FinishMission.Parser);
            dict.Add(PBDefine.FinishAchv, FinishAchv.Parser);
            dict.Add(PBDefine.MissionEvent, MissionEvent.Parser);
            dict.Add(PBDefine.MissionItem, MissionItem.Parser);
            dict.Add(PBDefine.MissionList, MissionList.Parser);
            dict.Add(PBDefine.AchvItem, AchvItem.Parser);
            dict.Add(PBDefine.AchvList, AchvList.Parser);
            dict.Add(PBDefine.Box, Box.Parser);
            dict.Add(PBDefine.Boxes, Boxes.Parser);
            dict.Add(PBDefine.Rewards, Rewards.Parser);
            dict.Add(PBDefine.Talents, Talents.Parser);
            dict.Add(PBDefine.TalentUnlock, TalentUnlock.Parser);
            dict.Add(PBDefine.SigninRecord, SigninRecord.Parser);
            dict.Add(PBDefine.SigninGet, SigninGet.Parser);
            dict.Add(PBDefine.ShopBuy, ShopBuy.Parser);
            dict.Add(PBDefine.ADShow, ADShow.Parser);
            dict.Add(PBDefine.ADList, ADList.Parser);
            dict.Add(PBDefine.ShopRecord, ShopRecord.Parser);
            dict.Add(PBDefine.RecordSave, RecordSave.Parser);
            dict.Add(PBDefine.MapRecordSave, MapRecordSave.Parser);
        }
    }
}