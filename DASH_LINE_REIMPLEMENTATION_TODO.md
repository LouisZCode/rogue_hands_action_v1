# 🎯 Dash Line Reimplementation TODO

**Status**: Complete removal completed, ready for fresh implementation  
**Date**: 2025-06-26  

## ✅ **Removal Completed:**
- ✅ **Enemy.tscn**: DashPreview node and script reference removed
- ✅ **Enemy.gd**: @onready dash_preview reference removed  
- ✅ **Enemy.gd**: update_enemy_dash_preview() function completely deleted
- ✅ **Enemy.gd**: All dash_preview calls removed from ATTACKING/RETREATING states
- ✅ **Enemy.gd**: Dash preview initialization removed from _ready()

## 🚀 **Ready for Reimplementation:**

### **Files to Consider:**
- **DashPreview.gd**: Class still exists, may be reused or replaced
- **Enemy.gd**: Clean slate for new dash line logic
- **Enemy.tscn**: Ready for new dash line node architecture

### **Implementation Ideas (User's Vision):**
- 🎯 **Better timing logic** for dash line visibility
- 🎯 **Improved visual feedback** during attack sequences  
- 🎯 **Enhanced user experience** for attack telegraphing
- 🎯 **More intuitive** dash line behavior

### **Technical Considerations:**
1. **State Integration**: How dash line interacts with AIState system
2. **Performance**: Efficient dash line rendering and updates
3. **Visual Polish**: Smooth show/hide transitions and styling
4. **Player Feedback**: Clear attack telegraphing without being overwhelming

### **Next Steps When Ready:**
1. **Design new dash line system** based on user requirements
2. **Choose implementation approach** (reuse DashPreview.gd vs new system)
3. **Create new dash line node** in Enemy.tscn if needed
4. **Implement state-based visibility logic** in Enemy.gd
5. **Add visual polish** and smooth transitions
6. **Test and iterate** based on gameplay feel

---

**🎉 Clean slate achieved! Ready for your improved dash line ideas!** 🎉