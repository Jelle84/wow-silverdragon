#!/usr/bin/python

import json
import re
import yaml

from . import NPC, types, pack_coords
from .zones import zoneid_to_mapid, zoneid_ignore

zone_map = False


class WowheadNPC(NPC):
    URL = 'http://www.wowhead.com'
    URL_PTR = 'http://ptr.wowhead.com'
    URL_BETA = 'http://bfa.wowhead.com'

    page = False
    _info = False

    def __page(self):
        if self.page is False:
            url = '%s/npc=%d' % (self.url(ptr=self.ptr, beta=self.beta), self.id)
            self.page = self.session.get(url).text
            if not self.page:
                print("Couldn't fetch", url)
        return self.page

    def __info(self):
        if self._info is False:
            # $.extend(g_npcs[69842], {"classification":2,"id":69842,"location":[5842,6138,5841,-1],"maxlevel":92,"minlevel":92,"name":"Zandalari Warbringer","react":[-1,-1],"type":7});
            info = re.search(r"\$\.extend\(g_npcs\[%d\], ({.+?})\);" % self.id, self.__page())
            if info:
                self._info = json.loads(info.group(1).replace('undefined', 'null'))
            else:
                self._info = {}
        return self._info

    def _name(self):
        info = re.search(r"g_pageInfo = {type: 1, typeId: \d+, name: \"(.+?)\"};", self.__page())
        if info:
            return self.html_decode(info.group(1).replace("\\'", "'").replace('\\"', '"'))

    def _creature_type(self):
        return types.get(self.__info().get('type'))

    def _locations(self):
        page = self.__page()
        if not page:
            return {}
        coords = {}
        zones = self.__info().get('location')
        if zones:
            for zone in zones:
                if zone == -1:
                    continue
                if zone in zoneid_ignore:
                    continue
                if not zoneid_to_mapid.get(zone):
                    print("Got location for unknown zone", zone, self.id)
                    continue
                coords[zoneid_to_mapid[zone]] = []
        match = re.search(r"var g_mapperData = ({[^;]+});", page)
        if not match:
            return {}
        alldata = json.loads(match.group(1))
        for zone, data in alldata.items():
            zone = int(zone)
            if zone in zoneid_ignore:
                continue
            if not zoneid_to_mapid.get(zone):
                print("Got location for unknown zone", zone, self.id)
                continue
            processed_coords = []
            # if we're in a floors situation:
            if type(data) == dict:
                print("FLOORS", data.keys())
                data = data.get("0", {})
            else:
                data = data[0]
            raw_coords = data.get('coords', [])
            for x, y in ((c[0] / 100, c[1] / 100) for c in raw_coords):
                for oldx, oldy in processed_coords:
                    if abs(oldx - x) < 0.05 and abs(oldy - y) < 0.05:
                        break
                else:
                    # list fully looped through, not broken.
                    processed_coords.append((x, y))
            coords[zoneid_to_mapid[zone]] = [pack_coords(c[0], c[1]) for c in processed_coords]
        return coords

    def _tameable(self):
        return bool('\\x5DTameable\\x20' in self.__page())

    def _elite(self):
        return self.__info().get('classification', 0) in (1, 2)

    def _level(self):
        return self.__info().get('maxlevel')

    def _quest(self):
        search = questSearch(self._name(), self.session)
        if search:
            return search
        info = re.search(r'<pre id="questtracking">/run print\(IsQuestFlaggedCompleted\((\d+)\)\)</pre>', self.__page())
        if info:
            if len(info.group(1)) > 3:
                # There's a lot of corrupt data on there...
                return int(info.group(1))

    def _expansion(self):
        patch = re.search(r'Added(?:\s|\\x20)in(?:\s|\\x20)patch(?:\s|\\x20)(\d+)', self.__page())
        if patch:
            return int(patch.group(1))

    @classmethod
    def query(cls, category, expansion, session, ptr=False, beta=False, cached=True, **kw):
        url = "%s/%s-npcs/classification:4:2?filter=39;%d;0" % (cls.url(ptr=ptr, beta=beta), category, expansion)
        print(url)

        if cached:
            page = session.get(url, **kw)
        else:
            with session.cache_disabled():
                page = session.get(url, **kw)

        match = re.search(r'new Listview\({[^{]+?"?data"?:\s*\[(.+?)\]}\);\n', page.text)
        if not match:
            print("None found")
            return {}
        npcs = {}
        for npc in (WowheadNPC(id, ptr=ptr, session=session) for id in re.findall(r'"id":(\d+)', match.group(1))):
            try:
                print(npc)
                npcs[npc.id] = npc
            except Exception as e:
                print("couldn't load npc", npc.id)
        return npcs


class WowHeadQuestSearch:
    def __init__(self):
        self.quests = False

    def __call__(self, name, session):
        if not self.quests:
            questpage = session.get('http://www.wowhead.com/quests/name:vignette').text
            match = re.search(r"^new Listview\({.+?id:\s*'quests',.*?data:\s*(.+)}\);$", questpage, re.MULTILINE)
            self.quests = [(int(q['id']), q['name']) for q in yaml.safe_load(match.group(1))]
            self.quests.sort()
        matcher = re.compile(r'\b%s\b' % name)
        for quest in self.quests:
            if matcher.search(quest[1]):
                return quest[0]

questSearch = WowHeadQuestSearch()
