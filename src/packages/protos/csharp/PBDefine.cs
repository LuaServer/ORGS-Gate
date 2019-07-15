using Google.Protobuf;
using System.Collections.Generic;
namespace Pb{
    public enum PBDefine{
        Unknow,
        Pack = 1,
        Error = 2,
        Operation = 3,
        CreateRole = 4,
        Delete = 101,
        Role = 1001,
        Prop = 1202,
        Props = 1201,
        Chapter = 1102,
        Chapters = 1101,
        FinishChapter = 1103,
        FinishMission = 1403,
        FinishAchv = 1503,
        MissionEvent = 1404,
        MissionItem = 1402,
        MissionList = 1401,
        AchvItem = 1502,
        AchvList = 1501,
        Box = 2002,
        Boxes = 2001,
        OpenBox = 2003,
        GainBox = 2004,
        Rewards = 102,
        Talent = 1302,
        Talents = 1301,
        TalentUnlock = 1303,
        SigninRecord = 1801,
        SigninGet = 1802,
        PayBuy = 2203,
        BuyItem = 1702,
        BuyList = 1701,
        ShopBuy = 1902,
        ADShow = 1603,
        ADItem = 1602,
        ADList = 1601,
        ShopRecord = 1901,
        GameRecord = 2101,
        RecordSave = 2102,
        ExchangeItem = 2103
    }

    public static class PBRegister
    {
        public static void Register(ref Dictionary<PBDefine, MessageParser>dict)
        {
            dict.Add(PBDefine.Pack, Pack.Parser);
            dict.Add(PBDefine.Error, Error.Parser);
            dict.Add(PBDefine.Operation, Operation.Parser);
            dict.Add(PBDefine.CreateRole, CreateRole.Parser);
            dict.Add(PBDefine.Delete, Delete.Parser);
            dict.Add(PBDefine.Role, Role.Parser);
            dict.Add(PBDefine.Prop, Prop.Parser);
            dict.Add(PBDefine.Props, Props.Parser);
            dict.Add(PBDefine.Chapter, Chapter.Parser);
            dict.Add(PBDefine.Chapters, Chapters.Parser);
            dict.Add(PBDefine.FinishChapter, FinishChapter.Parser);
            dict.Add(PBDefine.FinishMission, FinishMission.Parser);
            dict.Add(PBDefine.FinishAchv, FinishAchv.Parser);
            dict.Add(PBDefine.MissionEvent, MissionEvent.Parser);
            dict.Add(PBDefine.MissionItem, MissionItem.Parser);
            dict.Add(PBDefine.MissionList, MissionList.Parser);
            dict.Add(PBDefine.AchvItem, AchvItem.Parser);
            dict.Add(PBDefine.AchvList, AchvList.Parser);
            dict.Add(PBDefine.Box, Box.Parser);
            dict.Add(PBDefine.Boxes, Boxes.Parser);
            dict.Add(PBDefine.OpenBox, OpenBox.Parser);
            dict.Add(PBDefine.GainBox, GainBox.Parser);
            dict.Add(PBDefine.Rewards, Rewards.Parser);
            dict.Add(PBDefine.Talent, Talent.Parser);
            dict.Add(PBDefine.Talents, Talents.Parser);
            dict.Add(PBDefine.TalentUnlock, TalentUnlock.Parser);
            dict.Add(PBDefine.SigninRecord, SigninRecord.Parser);
            dict.Add(PBDefine.SigninGet, SigninGet.Parser);
            dict.Add(PBDefine.PayBuy, PayBuy.Parser);
            dict.Add(PBDefine.BuyItem, BuyItem.Parser);
            dict.Add(PBDefine.BuyList, BuyList.Parser);
            dict.Add(PBDefine.ShopBuy, ShopBuy.Parser);
            dict.Add(PBDefine.ADShow, ADShow.Parser);
            dict.Add(PBDefine.ADItem, ADItem.Parser);
            dict.Add(PBDefine.ADList, ADList.Parser);
            dict.Add(PBDefine.ShopRecord, ShopRecord.Parser);
            dict.Add(PBDefine.GameRecord, GameRecord.Parser);
            dict.Add(PBDefine.RecordSave, RecordSave.Parser);
            dict.Add(PBDefine.ExchangeItem, ExchangeItem.Parser);
        }
    }
}